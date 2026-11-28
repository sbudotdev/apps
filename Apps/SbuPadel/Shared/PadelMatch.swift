/// A match as the list of who won each point. The score is replayed from it, so undo is
/// dropping the last point and saving is saving the list.
nonisolated struct PadelMatch: Codable, Equatable, Sendable {
    var deuceRule: DeuceRule = .goldenPoint
    var firstServer: Side = .us
    private(set) var points: [Side] = []

    var score: MatchScore {
        points.reduce(into: MatchScore(deuceRule: deuceRule, firstServer: firstServer)) { $0.add(pointTo: $1) }
    }

    var hasStarted: Bool { points.isEmpty == false }

    /// Adds a point, unless the match is over.
    mutating func point(to side: Side) {
        guard score.winner == nil else { return }
        points.append(side)
    }

    /// Takes back the last point; nothing at the start.
    mutating func undo() {
        _ = points.popLast()
    }
}
