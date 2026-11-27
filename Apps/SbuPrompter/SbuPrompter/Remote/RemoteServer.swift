import AppKit
@preconcurrency import MultipeerConnectivity
import Observation

/// The Mac end of the iPhone remote: announces itself on the local network with MultipeerConnectivity
/// (encrypted, nothing leaves the LAN), lets `RemoteGate` decide who may drive the prompter,
/// and sends the prompter's status to the paired iPhones whenever it changes.
@Observable
final class RemoteServer: NSObject {
    static let serviceType = "sbu-prompter"
    private static let tokensKey = "remoteTokens"
    private static let idKey = "remoteID"
    /// The line being read changes several times a second while the text scrolls.
    private static let statusInterval: TimeInterval = 0.1

    private(set) var gate: RemoteGate<MCPeerID>

    @ObservationIgnored var onCommand: ((PrompterCommand) -> Void)?
    @ObservationIgnored var status: () -> PrompterStatus? = { nil }

    @ObservationIgnored private let peer: MCPeerID
    /// MCSession is thread-safe; the advertiser's callback hands it out off the main thread.
    @ObservationIgnored nonisolated(unsafe) private let session: MCSession
    @ObservationIgnored private let advertiser: MCNearbyServiceAdvertiser
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var lastSent: PrompterStatus?
    /// Keeps App Nap off while an iPhone drives: it throttles the status timer to seconds when the
    /// prompter is on another Space or behind other windows.
    @ObservationIgnored private var driving: NSObjectProtocol?

    override init() {
        // shortcut: tokens sit in the sandboxed defaults, not the Keychain; they only let a paired
        // iPhone on the same LAN skip the code. Move them to the Keychain if they ever unlock more.
        let tokens = UserDefaults.standard.stringArray(forKey: Self.tokensKey) ?? []
        gate = RemoteGate(tokens: Set(tokens))
        #if DEBUG
        // Store screenshots must not show the name of the Mac they were taken on.
        let name = UserDefaults.standard.string(forKey: "SbuPrompterPeerName") ?? Host.current().localizedName
        #else
        let name = Host.current().localizedName
        #endif
        peer = MCPeerID(displayName: name ?? "Mac")
        session = MCSession(peer: peer, securityIdentity: nil, encryptionPreference: .required)
        // A random id kept across launches: the iPhone tells this Mac opened again from another Mac
        // with the same name, and joins it again with its token.
        #if DEBUG
        // Test Macs named on the command line run beside the real one: each needs its own id.
        let idKey = UserDefaults.standard.string(forKey: "SbuPrompterPeerName").map { "\(Self.idKey)-\($0)" } ?? Self.idKey
        #else
        let idKey = Self.idKey
        #endif
        let id = UserDefaults.standard.string(forKey: idKey) ?? UUID().uuidString
        UserDefaults.standard.set(id, forKey: idKey)
        advertiser = MCNearbyServiceAdvertiser(peer: peer, discoveryInfo: ["id": id], serviceType: Self.serviceType)
        super.init()
        session.delegate = self
        advertiser.delegate = self
    }

    var code: String { gate.code }
    /// The paired iPhone driving the prompter now, if any.
    var connectedName: String? { gate.driver?.displayName }

    func start() {
        advertiser.startAdvertisingPeer()
        let timer = Timer(timeInterval: Self.statusInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.pushStatusIfChanged() }
        }
        // `.common`, or the timer stops while the person drags or scrolls on the Mac.
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    /// Every iPhone needs the code again, and the ones connected now are dropped.
    func forgetAll() {
        gate.forgetAll()
        saveTokens()
        session.disconnect()
        updateDriving()
    }

    private func receive(_ data: Data, from peer: MCPeerID) {
        // Another protocol version or garbage: nothing this Mac can answer in a way the peer reads.
        guard let message = try? RemoteCodec.decode(data) else { return }
        let hadTokens = gate.tokens
        for action in gate.receive(message, from: peer) {
            switch action {
            case .send(let reply): send(reply, to: [peer])
            case .sendStatus:
                // To every paired iPhone, so the timer does not send the same status again.
                if let status = status() {
                    lastSent = status
                    send(.status(status), to: session.connectedPeers.filter(gate.isTrusted))
                }
            case .perform(let command): onCommand?(command)
            }
        }
        if gate.tokens != hadTokens { saveTokens() }
        updateDriving()
    }

    private func updateDriving() {
        if gate.driver == nil {
            driving.map(ProcessInfo.processInfo.endActivity)
            driving = nil
        } else if driving == nil {
            driving = ProcessInfo.processInfo.beginActivity(options: .userInitiated, reason: "iPhone remote connected")
        }
    }

    private func pushStatusIfChanged() {
        let trusted = session.connectedPeers.filter(gate.isTrusted)
        guard !trusted.isEmpty, let status = status(), status != lastSent else { return }
        lastSent = status
        send(.status(status), to: trusted)
    }

    private func send(_ message: RemoteMessage, to peers: [MCPeerID]) {
        guard let data = try? RemoteCodec.encode(message) else { return }
        try? session.send(data, toPeers: peers, with: .reliable)
    }

    private func peerChanged(_ peer: MCPeerID, connected: Bool) {
        guard !connected else { return }
        gate.disconnected(peer)
        updateDriving()
    }

    private func saveTokens() {
        UserDefaults.standard.set(gate.tokens.sorted(), forKey: Self.tokensKey)
    }
}

extension RemoteServer: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID,
                                withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Anyone nearby may connect; only the code or a saved token lets them drive (RemoteGate).
        invitationHandler(true, session)
    }
}

extension RemoteServer: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in self.peerChanged(peerID, connected: state == .connected) }
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        Task { @MainActor in self.receive(data, from: peerID) }
    }

    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String,
                             fromPeer peerID: MCPeerID) {}
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String,
                             fromPeer peerID: MCPeerID, with progress: Progress) {}
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String,
                             fromPeer peerID: MCPeerID, at localURL: URL?, withError error: (any Error)?) {}
}
