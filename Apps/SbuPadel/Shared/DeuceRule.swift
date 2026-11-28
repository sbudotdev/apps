/// What happens at 40 all, chosen before the match.
nonisolated enum DeuceRule: String, Codable, Sendable, CaseIterable {
    /// The next point wins the game.
    case goldenPoint
    /// A pair needs two points in a row from 40 all.
    case advantages
}
