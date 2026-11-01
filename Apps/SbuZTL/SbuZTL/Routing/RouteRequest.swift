import Foundation

/// What a route has to respect.
nonisolated struct RouteRequest: Sendable {
    let start: Point
    let destination: Point
    let vehicle: Vehicle
    let departure: Date
    let permits: [Permit]
    let avoidsPaidZones: Bool
}
