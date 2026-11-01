import Foundation

/// The zones bundled with the app, updated only with app releases.
nonisolated struct ZoneCatalog: Sendable {
    let zones: [Zone]

    private struct Record: Decodable {
        let id: String
        let city: City
        let name: String
        let kind: ZoneKind
        let act: String?
        let exceptions: String?
        let section: String?
        let polygons: [[[[Double]]]]
    }

    init(zones: [Zone]) {
        self.zones = zones
    }

    init(data: Data) throws {
        let records = try JSONDecoder().decode([Record].self, from: data)
        zones = records.map { record in
            Zone(id: record.id, city: record.city, name: record.name, kind: record.kind, act: record.act,
                 exceptions: record.exceptions, section: record.section,
                 polygons: record.polygons.map { rings in
                     let loops = rings.map { $0.map { Point($0[0], $0[1]) } }
                     return Polygon(ring: loops[0], holes: Array(loops.dropFirst()))
                 })
        }
    }

    static let bundled: ZoneCatalog = {
        guard let url = Bundle.main.url(forResource: "zones", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let catalog = try? ZoneCatalog(data: data) else { return ZoneCatalog(zones: []) }
        return catalog
    }()

    func zones(at p: Point) -> [Zone] {
        zones.filter { $0.contains(p) }
    }

    func zones(in city: City) -> [Zone] {
        zones.filter { $0.city == city }
    }

    /// The covered city around a point, from its Area B or sector perimeters; `nil` is "non coperto", never "puoi entrare".
    func city(at p: Point) -> City? {
        for city in City.allCases where city.bounds.contains(p) { return city }
        return nil
    }
}
