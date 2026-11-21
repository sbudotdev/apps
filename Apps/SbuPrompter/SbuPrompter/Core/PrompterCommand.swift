/// What can drive the prompter: the menu, the global shortcuts and, later, the iPhone remote.
/// Codable so the remote can send it over the local network.
nonisolated enum PrompterCommand: Codable, Sendable, Hashable {
    case togglePlay
    case faster
    case slower
    case setSpeed(Double)
    case nextCue
    case previousCue
    case jumpToCue(Int)
    case returnFromCue
    case rewind
    case toggleVisibility
}
