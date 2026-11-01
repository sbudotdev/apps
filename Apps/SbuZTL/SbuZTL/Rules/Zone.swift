import Foundation

/// A restricted zone from a city's official dataset.
nonisolated struct Zone: Sendable, Identifiable {
    let id: String
    let city: City
    let name: String
    let kind: ZoneKind
    /// The act that established it, in the city's own words.
    let act: String?
    /// Who is exempt, in the city's own words.
    let exceptions: String?
    /// Which stretch of road, in the city's own words.
    let section: String?
    let polygons: [Polygon]

    func contains(_ p: Point) -> Bool {
        polygons.contains { $0.contains(p) }
    }
}
