import Foundation

/// One reading from the GPS.
nonisolated struct LocationFix: Sendable, Equatable {
    let point: Point
    let accuracy: Double
    let speed: Double
    let date: Date
}
