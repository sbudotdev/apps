import CoreLocation

/// A place on Earth.
nonisolated struct Point: Sendable, Hashable, Codable {
    let lat: Double
    let lon: Double

    init(_ lat: Double, _ lon: Double) {
        self.lat = lat
        self.lon = lon
    }

    init(_ coordinate: CLLocationCoordinate2D) {
        self.init(coordinate.latitude, coordinate.longitude)
    }

    var coordinate: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: lat, longitude: lon) }

    /// Equirectangular metres: accurate enough at city scale.
    func metres(to other: Point) -> Double {
        let dLat = (other.lat - lat) * 111_320
        let dLon = (other.lon - lon) * 111_320 * cos(lat * .pi / 180)
        return (dLat * dLat + dLon * dLon).squareRoot()
    }

    /// Degrees clockwise from north, towards `other`.
    func bearing(to other: Point) -> Double {
        let dLat = other.lat - lat
        let dLon = (other.lon - lon) * cos(lat * .pi / 180)
        let degrees = atan2(dLon, dLat) * 180 / .pi
        return degrees < 0 ? degrees + 360 : degrees
    }
}
