/// What the Mac and the iPhone remote say to each other over MultipeerConnectivity.
/// Sent inside `RemoteCodec`'s versioned envelope.
nonisolated enum RemoteMessage: Codable, Sendable, Equatable {
    /// iPhone: the 4-digit code shown on the Mac, the first time.
    case pair(code: String)
    /// iPhone: the token the Mac gave last time, so no code is needed.
    case resume(token: String)
    /// Mac: paired; keep this token for next time.
    case paired(token: String)
    /// Mac: the code or token is wrong or missing; ask for the code.
    case pairingRequired
    /// iPhone: drive the prompter.
    case command(PrompterCommand)
    /// Mac: where the prompter is now.
    case status(PrompterStatus)
}
