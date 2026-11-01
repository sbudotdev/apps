import Foundation

/// Drives outside the bundled graph, from a provider that knows those roads.
protocol ApproachRouter: Sendable {
    nonisolated func leg(from start: Point, to end: Point) async throws -> ApproachLeg
}
