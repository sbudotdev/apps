import Foundation

/// The OSM parkings bundled with the app, from Data/build_parkings.py. Data (c) OpenStreetMap, ODbL.
nonisolated struct ParkingCatalog: Sendable {
    /// Beyond this span, about 6 km, marks would hide the map.
    private static let maxSpan = 0.06
    private static let maxShown = 150

    let parkings: [Parking]

    private struct Columns: Decodable {
        let lat: [Double]
        let lon: [Double]
        let names: [String]
    }

    init(parkings: [Parking]) {
        self.parkings = parkings
    }

    init(data: Data) throws {
        let c = try JSONDecoder().decode(Columns.self, from: data)
        parkings = c.lat.indices.map { Parking(id: $0, point: Point(c.lat[$0], c.lon[$0]), name: c.names[$0]) }
    }

    static let bundled: ParkingCatalog = {
        guard let url = Bundle.main.url(forResource: "parkings", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let catalog = try? ParkingCatalog(data: data) else { return ParkingCatalog(parkings: []) }
        return catalog
    }()

    /// What fits the map's region, nearest to its centre first.
    func visible(latitude: Double, longitude: Double, latitudeDelta: Double, longitudeDelta: Double) -> [Parking] {
        guard latitudeDelta <= Self.maxSpan else { return [] }
        let centre = Point(latitude, longitude)
        let inside = parkings.filter {
            abs($0.point.lat - latitude) <= latitudeDelta / 2 && abs($0.point.lon - longitude) <= longitudeDelta / 2
        }
        return Array(inside.sorted { $0.point.metres(to: centre) < $1.point.metres(to: centre) }.prefix(Self.maxShown))
    }
}
