import Foundation

public struct Point: Sendable, Hashable {
    public let lat: Double
    public let lon: Double

    public init(_ lat: Double, _ lon: Double) {
        self.lat = lat
        self.lon = lon
    }

    /// Equirectangular metres: accurate enough at city scale.
    func metres(to other: Point) -> Double {
        let dLat = (other.lat - lat) * 111_320
        let dLon = (other.lon - lon) * 111_320 * cos(lat * .pi / 180)
        return (dLat * dLat + dLon * dLon).squareRoot()
    }
}

public struct Zone: Sendable {
    public let name: String
    public let ring: [Point]

    public init(name: String, ring: [Point]) {
        self.name = name
        self.ring = ring
    }

    public func contains(_ p: Point) -> Bool {
        var inside = false
        var j = ring.count - 1
        for i in ring.indices {
            let a = ring[i], b = ring[j]
            if (a.lat > p.lat) != (b.lat > p.lat),
               p.lon < (b.lon - a.lon) * (p.lat - a.lat) / (b.lat - a.lat) + a.lon {
                inside.toggle()
            }
            j = i
        }
        return inside
    }

    /// Metres of the route inside the zone. The stretch before the route first leaves the zone
    /// doesn't count: a start inside can't be avoided.
    /// shortcut: samples every 25 m, enough for a spike; a real app needs exact segment clipping.
    public func metresInside(route: [Point]) -> Double {
        var left = false
        var total = 0.0
        for (a, b) in zip(route, route.dropFirst()) {
            let length = a.metres(to: b)
            let steps = max(1, Int(length / 25))
            for step in 0..<steps {
                let t = (Double(step) + 0.5) / Double(steps)
                let p = Point(a.lat + (b.lat - a.lat) * t, a.lon + (b.lon - a.lon) * t)
                if contains(p) {
                    if left { total += length / Double(steps) }
                } else {
                    left = true
                }
            }
        }
        return total
    }

    /// shortcut: pushes vertices away from the centroid, valid only for star-shaped rings; real perimeters need a true offset.
    public func outerRing(metres: Double) -> [Point] {
        let centre = Point(
            ring.map(\.lat).reduce(0, +) / Double(ring.count),
            ring.map(\.lon).reduce(0, +) / Double(ring.count))
        return ring.map { p in
            let scale = 1 + metres / centre.metres(to: p)
            return Point(centre.lat + (p.lat - centre.lat) * scale, centre.lon + (p.lon - centre.lon) * scale)
        }
    }

    /// The two ways around the outer ring between origin and destination, each thinned to at most `limit` stops.
    public func detours(from origin: Point, to destination: Point, metres: Double = 150, limit: Int = 3) -> [[Point]] {
        let outer = outerRing(metres: metres)
        let start = Self.nearestIndex(in: outer, to: origin)
        let end = Self.nearestIndex(in: outer, to: destination)
        guard start != end else { return [[outer[start]]] }
        let count = outer.count
        let forward = Array(stride(from: 0, through: (end - start + count) % count, by: 1)).map { outer[(start + $0) % count] }
        let backward = Array(stride(from: 0, through: (start - end + count) % count, by: 1)).map { outer[(start - $0 + count) % count] }
        return [forward, backward].map { Self.thin($0, to: limit) }
    }

    public func nearestOuterPoint(to p: Point, metres: Double = 150) -> Point {
        let outer = outerRing(metres: metres)
        return outer[Self.nearestIndex(in: outer, to: p)]
    }

    private static func nearestIndex(in points: [Point], to p: Point) -> Int {
        points.indices.min { points[$0].metres(to: p) < points[$1].metres(to: p) } ?? 0
    }

    private static func thin(_ points: [Point], to limit: Int) -> [Point] {
        guard points.count > limit else { return points }
        return (0..<limit).map { points[$0 * (points.count - 1) / max(limit - 1, 1)] }
    }
}
