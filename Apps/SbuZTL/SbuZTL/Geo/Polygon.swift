/// A ring with its holes, in the form of a GeoJSON polygon.
nonisolated struct Polygon: Sendable {
    let ring: [Point]
    let holes: [[Point]]
    private let minLat: Double
    private let maxLat: Double
    private let minLon: Double
    private let maxLon: Double

    init(ring: [Point], holes: [[Point]] = []) {
        self.ring = ring
        self.holes = holes
        minLat = ring.map(\.lat).min() ?? 0
        maxLat = ring.map(\.lat).max() ?? 0
        minLon = ring.map(\.lon).min() ?? 0
        maxLon = ring.map(\.lon).max() ?? 0
    }

    func contains(_ p: Point) -> Bool {
        guard p.lat >= minLat, p.lat <= maxLat, p.lon >= minLon, p.lon <= maxLon else { return false }
        var inside = false
        for loop in [ring] + holes {
            var j = loop.count - 1
            for i in loop.indices {
                let a = loop[i], b = loop[j]
                if (a.lat > p.lat) != (b.lat > p.lat),
                   p.lon < (b.lon - a.lon) * (p.lat - a.lat) / (b.lat - a.lat) + a.lon {
                    inside.toggle()
                }
                j = i
            }
        }
        return inside
    }
}
