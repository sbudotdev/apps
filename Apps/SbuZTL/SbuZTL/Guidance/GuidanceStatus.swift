/// What the status line says during the drive.
nonisolated enum GuidanceStatus: Sendable, Equatable {
    case starting
    case following
    case rerouting
    case weakSignal
    case arrived
}
