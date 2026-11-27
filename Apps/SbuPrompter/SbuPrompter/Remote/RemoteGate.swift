import Foundation

/// Decides what the Mac does with each message from an iPhone: pairing with the 4-digit code
/// shown in the menu, resuming with a saved token, and running commands only for paired peers.
nonisolated struct RemoteGate<Peer: Hashable> {
    enum Action: Equatable {
        case send(RemoteMessage)
        case sendStatus
        case perform(PrompterCommand)
    }

    /// Wrong codes in a row before the code changes and pairing closes for a while.
    static var maxFailures: Int { 5 }
    /// The first pause after too many wrong codes; it doubles each time, until a pairing succeeds,
    /// so trying all 10 000 codes takes years.
    static var firstLockout: TimeInterval { 30 }

    private(set) var code: String
    /// Tokens of the iPhones paired before; saved by the caller.
    private(set) var tokens: Set<String>
    private var trusted: Set<Peer> = []
    /// The paired iPhone that joined last and is still connected: the one the menu names.
    private(set) var driver: Peer?
    private var failures = 0
    private var lockouts = 0
    private var lockedUntil: Date?
    private let makeCode: () -> String
    private let makeToken: () -> String
    private let now: () -> Date

    init(tokens: Set<String> = [], makeCode: @escaping () -> String = Self.randomCode,
         makeToken: @escaping () -> String = { UUID().uuidString }, now: @escaping () -> Date = Date.init) {
        self.tokens = tokens
        self.makeCode = makeCode
        self.makeToken = makeToken
        self.now = now
        code = makeCode()
    }

    func isTrusted(_ peer: Peer) -> Bool { trusted.contains(peer) }

    mutating func receive(_ message: RemoteMessage, from peer: Peer) -> [Action] {
        switch message {
        case .pair(let attempt):
            if let lockedUntil, now() < lockedUntil { return [.send(.pairingPaused)] }
            guard attempt == code else {
                failures += 1
                if failures >= Self.maxFailures {
                    lockedUntil = now().addingTimeInterval(Self.firstLockout * pow(2, Double(lockouts)))
                    lockouts += 1
                    newCode()
                    return [.send(.pairingPaused)]
                }
                return [.send(.pairingRequired)]
            }
            let token = makeToken()
            tokens.insert(token)
            lockouts = 0
            lockedUntil = nil
            newCode()
            return trust(peer, token: token)
        case .resume(let token):
            guard tokens.contains(token) else { return [.send(.pairingRequired)] }
            return trust(peer, token: token)
        case .command(let command):
            // The status right after the command: the iPhone shows its effect without waiting for the timer.
            return trusted.contains(peer) ? [.perform(command), .sendStatus] : [.send(.pairingRequired)]
        case .paired, .pairingRequired, .pairingPaused, .status:
            return []
        }
    }

    mutating func disconnected(_ peer: Peer) {
        trusted.remove(peer)
        if driver == peer { driver = trusted.first }
    }

    /// "Dimentica gli iPhone": every iPhone needs the code again, and a pause caused by
    /// someone else guessing ends, so the person at the Mac can always pair.
    mutating func forgetAll() {
        tokens = []
        trusted = []
        driver = nil
        lockouts = 0
        lockedUntil = nil
        newCode()
    }

    static func randomCode() -> String {
        String(format: "%04d", Int.random(in: 0...9999))
    }

    private mutating func trust(_ peer: Peer, token: String) -> [Action] {
        trusted.insert(peer)
        driver = peer
        return [.send(.paired(token: token)), .sendStatus]
    }

    private mutating func newCode() {
        code = makeCode()
        failures = 0
    }
}
