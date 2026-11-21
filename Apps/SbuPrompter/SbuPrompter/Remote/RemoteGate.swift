import Foundation

/// Decides what the Mac does with each message from an iPhone: pairing with the 4-digit code
/// shown in the menu, resuming with a saved token, and running commands only for paired peers.
nonisolated struct RemoteGate<Peer: Hashable> {
    enum Action: Equatable {
        case send(RemoteMessage)
        case sendStatus
        case perform(PrompterCommand)
    }

    /// Wrong codes in a row before the code changes, so it cannot be guessed by trying them all.
    static var maxFailures: Int { 5 }

    private(set) var code: String
    /// Tokens of the iPhones paired before; saved by the caller.
    private(set) var tokens: Set<String>
    private var trusted: Set<Peer> = []
    private var failures = 0
    private let makeCode: () -> String
    private let makeToken: () -> String

    init(tokens: Set<String> = [], makeCode: @escaping () -> String = Self.randomCode,
         makeToken: @escaping () -> String = { UUID().uuidString }) {
        self.tokens = tokens
        self.makeCode = makeCode
        self.makeToken = makeToken
        code = makeCode()
    }

    var hasTrustedPeer: Bool { !trusted.isEmpty }

    func isTrusted(_ peer: Peer) -> Bool { trusted.contains(peer) }

    mutating func receive(_ message: RemoteMessage, from peer: Peer) -> [Action] {
        switch message {
        case .pair(let attempt):
            guard attempt == code else {
                failures += 1
                if failures >= Self.maxFailures { newCode() }
                return [.send(.pairingRequired)]
            }
            let token = makeToken()
            tokens.insert(token)
            newCode()
            return trust(peer, token: token)
        case .resume(let token):
            guard tokens.contains(token) else { return [.send(.pairingRequired)] }
            return trust(peer, token: token)
        case .command(let command):
            return trusted.contains(peer) ? [.perform(command)] : [.send(.pairingRequired)]
        case .paired, .pairingRequired, .status:
            return []
        }
    }

    mutating func disconnected(_ peer: Peer) {
        trusted.remove(peer)
    }

    /// "Dimentica gli iPhone": every iPhone needs the code again.
    mutating func forgetAll() {
        tokens = []
        trusted = []
        newCode()
    }

    static func randomCode() -> String {
        String(format: "%04d", Int.random(in: 0...9999))
    }

    private mutating func trust(_ peer: Peer, token: String) -> [Action] {
        trusted.insert(peer)
        return [.send(.paired(token: token)), .sendStatus]
    }

    private mutating func newCode() {
        code = makeCode()
        failures = 0
    }
}
