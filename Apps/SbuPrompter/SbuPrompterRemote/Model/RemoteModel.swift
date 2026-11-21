import CoreGraphics
import Foundation
import Observation
import SwiftUI

/// The remote's state: which Macs are nearby, pairing, and the prompter's status.
/// `MacLink` feeds it what happens on the network and carries out `send` and `connect`.
@Observable
final class RemoteModel {
    enum Phase: Equatable {
        /// No Mac joined yet: the empty screen.
        case searching
        case connecting(String)
        case needsCode(mac: String, wrong: Bool)
        case connected(String)
        /// The Mac speaks another protocol version.
        case outdated
    }

    /// The shortest drag that counts as a swipe, in points.
    static let swipeDistance: CGFloat = 40
    /// A drag shorter than this is a tap, in points.
    static let tapSlop: CGFloat = 10

    private(set) var macs: [String] = []
    private(set) var phase: Phase = .searching
    private(set) var status: PrompterStatus?
    /// Grows with every command sent, so the view plays one haptic each.
    private(set) var commandCount = 0
    /// Wrong codes so far; the code field starts empty again after each one.
    private(set) var wrongCodes = 0
    /// The Mac refuses codes for a while after too many wrong ones.
    private(set) var isPairingPaused = false
    private(set) var isInBackground = false

    @ObservationIgnored var send: (RemoteMessage) -> Void = { _ in }
    @ObservationIgnored var connect: (String) -> Void = { _ in }

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var sentCode = false
    /// Failed invitations to the current Mac; Multipeer often drops the first after a relaunch.
    @ObservationIgnored private var failedAttempts = 0
    @ObservationIgnored private var hasStarted = false
    static let maxAttempts = 3
    private static let tokensKey = "macTokens"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var currentMac: String? {
        switch phase {
        case .connecting(let mac), .connected(let mac), .needsCode(let mac, _): mac
        case .searching, .outdated: nil
        }
    }

    func isPaired(with mac: String) -> Bool { tokens[mac] != nil }

    /// The reader holds the phone without touching it: no auto-lock while it drives the Mac.
    var keepsScreenOn: Bool {
        guard case .connected = phase else { return false }
        return !isInBackground
    }

    /// Returns true when the link has to start looking again: at launch and back from the
    /// background, where iOS drops the session. Control Center and notifications only make the
    /// app inactive, and the session survives them.
    func sceneChanged(to scene: ScenePhase) -> Bool {
        switch scene {
        case .background:
            isInBackground = true
            return false
        case .active:
            defer { hasStarted = true; isInBackground = false }
            return !hasStarted || isInBackground
        default:
            return false
        }
    }

    // MARK: From the network

    func found(_ names: [String]) {
        macs = names.sorted()
        guard phase == .searching else { return }
        if let paired = macs.first(where: isPaired) {
            choose(paired)
        } else if macs.count == 1 {
            choose(macs[0])
        }
    }

    func connected(to mac: String) {
        if let token = tokens[mac] {
            phase = .connecting(mac)
            send(.resume(token: token))
        } else {
            phase = .needsCode(mac: mac, wrong: false)
        }
    }

    func disconnected(from mac: String) {
        guard mac == currentMac else { return }
        if phase == .connecting(mac), status == nil, failedAttempts + 1 < Self.maxAttempts, macs.contains(mac) {
            failedAttempts += 1
            connect(mac)
            return
        }
        failedAttempts = 0
        phase = .searching
        status = nil
        sentCode = false
    }

    func receive(_ message: RemoteMessage) {
        guard let mac = currentMac else { return }
        switch message {
        case .paired(let token):
            failedAttempts = 0
            isPairingPaused = false
            tokens[mac] = token
            phase = .connected(mac)
        case .pairingRequired, .pairingPaused:
            tokens[mac] = nil
            if sentCode { wrongCodes += 1 }
            isPairingPaused = message == .pairingPaused
            phase = .needsCode(mac: mac, wrong: sentCode)
        case .status(let status):
            self.status = status
        case .pair, .resume, .command:
            break
        }
        sentCode = false
    }

    func outdated() {
        phase = .outdated
        status = nil
    }

    // MARK: From the person

    func choose(_ mac: String) {
        phase = .connecting(mac)
        connect(mac)
    }

    func enter(code: String) {
        guard code.count == 4, code.allSatisfy(\.isASCII), code.allSatisfy(\.isNumber) else { return }
        sentCode = true
        send(.pair(code: code))
    }

    func perform(_ command: PrompterCommand) {
        guard case .connected = phase else { return }
        send(.command(command))
        commandCount += 1
    }

    func forget(_ mac: String) {
        tokens[mac] = nil
    }

    /// Up and down change the speed; left and right move between cues, like turning a page.
    /// A drag that barely moves is a tap: start or pause.
    static func command(forSwipe translation: CGSize) -> PrompterCommand? {
        let (dx, dy) = (translation.width, translation.height)
        let distance = max(abs(dx), abs(dy))
        if distance < tapSlop { return .togglePlay }
        guard distance >= swipeDistance else { return nil }
        if abs(dy) > abs(dx) { return dy < 0 ? .faster : .slower }
        return dx < 0 ? .nextCue : .previousCue
    }

    // shortcut: tokens sit in UserDefaults, not the Keychain; they only skip the 4-digit code
    // on the same LAN. Move them to the Keychain if they ever unlock more.
    private var tokens: [String: String] {
        get { defaults.dictionary(forKey: Self.tokensKey) as? [String: String] ?? [:] }
        set { defaults.set(newValue, forKey: Self.tokensKey) }
    }
}
