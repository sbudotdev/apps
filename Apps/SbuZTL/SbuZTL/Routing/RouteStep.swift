import Foundation

/// One instruction: what to do when the route reaches `startMetre`.
nonisolated struct RouteStep: Sendable, Equatable {
    let maneuver: Maneuver
    let street: String?
    let startMetre: Double
    /// Apple's own words, for the stretch driven with MapKit outside the graph.
    let instruction: String?
}
