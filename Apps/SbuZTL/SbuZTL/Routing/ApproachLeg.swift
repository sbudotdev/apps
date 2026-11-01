import Foundation

/// A drive computed outside the graph.
nonisolated struct ApproachLeg: Sendable {
    let points: [Point]
    let seconds: Double
    let steps: [ApproachStep]
}
