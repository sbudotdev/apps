import Foundation

/// A route ready to preview and to follow.
nonisolated struct RoutePlan: Sendable {
    /// Polyline with its running distance.
    let points: [Point]
    let cumulative: [Double]
    let steps: [RouteStep]
    /// Speed limit in km/h on the segment that starts at each point; 0 where OSM doesn't say.
    let limits: [Int]
    let seconds: Double
    /// True when part of the route lies outside the bundled graph: zones there aren't checked.
    let isPartlyUncovered: Bool
    /// Metres on foot from the end of the route to the destination in a closed zone.
    let walkMetres: Double?
    /// The closed zone the destination lies in.
    let destinationZone: String?
    /// The closed zone the trip starts in: the route only leaves it.
    let startZone: String?
    let destination: Point

    var metres: Double { cumulative.last ?? 0 }
}
