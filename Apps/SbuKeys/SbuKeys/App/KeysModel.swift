import Foundation
import Observation

/// The app's state: the settings, today's count, and the tap that feeds the sound.
@Observable
final class KeysModel {
    private enum Key {
        static let isOn = "isOn"
        static let keySwitch = "keySwitch"
        static let volume = "volume"
        static let isSpatial = "isSpatial"
        static let tallyDay = "tallyDay"
        static let tallyCount = "tallyCount"
    }

    var isOn: Bool {
        didSet { defaults.set(isOn, forKey: Key.isOn) }
    }

    var keySwitch: KeySwitch {
        didSet {
            defaults.set(keySwitch.rawValue, forKey: Key.keySwitch)
            player.load(keySwitch)
        }
    }

    /// 0 to 1, on top of the Mac's own volume.
    var volume: Double {
        didSet {
            defaults.set(volume, forKey: Key.volume)
            player.volume = Float(volume)
        }
    }

    /// Each key sounds from where it sits on the keyboard.
    var isSpatial: Bool {
        didSet { defaults.set(isSpatial, forKey: Key.isSpatial) }
    }

    private(set) var tally: KeystrokeTally
    /// `false` until Input Monitoring is granted and the tap runs.
    private(set) var isListening = false

    private let defaults: UserDefaults
    private let tap = KeyTap()
    private let player = KeySoundPlayer()
    private var waitForAccess: Task<Void, Never>?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [Key.isOn: true, Key.volume: 0.6, Key.isSpatial: true])
        isOn = defaults.bool(forKey: Key.isOn)
        keySwitch = defaults.string(forKey: Key.keySwitch).flatMap(KeySwitch.init) ?? .tactile
        volume = defaults.double(forKey: Key.volume)
        isSpatial = defaults.bool(forKey: Key.isSpatial)
        tally = KeystrokeTally(
            day: defaults.object(forKey: Key.tallyDay) as? Date ?? .distantPast,
            count: defaults.integer(forKey: Key.tallyCount))

        player.load(keySwitch)
        player.volume = Float(volume)
        tap.onKey = { [weak self] keyCode, isDown in self?.handle(keyCode: keyCode, isDown: isDown) }
        startListening()
    }

    /// The count to show now: zero after midnight even before the first key of the day.
    func countToday(now: Date = .now) -> Int {
        tally.count(on: now)
    }

    /// Asks for Input Monitoring, then starts as soon as it is granted.
    func requestAccess() {
        KeyTap.requestAccess()
        startListening()
    }

    private func startListening() {
        isListening = tap.start()
        guard !isListening, waitForAccess == nil else { return }
        // macOS has no callback for the grant: check once a second while the switch is off.
        waitForAccess = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self else { return }
                if tap.start() {
                    isListening = true
                    waitForAccess = nil
                    return
                }
            }
        }
    }

    private func handle(keyCode: Int, isDown: Bool) {
        if isDown {
            tally.record(at: .now)
            defaults.set(tally.day, forKey: Key.tallyDay)
            defaults.set(tally.count, forKey: Key.tallyCount)
        }
        guard isOn else { return }
        let pan = isSpatial ? KeyPan.pan(forKeyCode: keyCode) : 0
        player.play(KeyKind(keyCode: keyCode), keySwitch: keySwitch, isDown: isDown, pan: pan)
    }
}
