/// What the last point closed, for the haptic that goes with it.
nonisolated enum MatchEvent: Equatable, Sendable {
    case point
    case game
    case set
    case match
}
