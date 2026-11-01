// Throwaway: does a bundled OSM graph with A* avoid official ZTL perimeters?
// Usage: ztlgraph <data-dir> <routes-out.json>
import Foundation
@preconcurrency import MapKit
import ZTLCore

let base = URL(fileURLWithPath: CommandLine.arguments[1])

func zones(_ name: String) throws -> [Zone] {
    let raw = try JSONDecoder().decode(
        [[[[Double]]]].self, from: Data(contentsOf: base.appendingPathComponent("zones-\(name).json")))
    return raw.map { rings in
        let loops = rings.map { $0.map { Point($0[0], $0[1]) } }
        return Zone(name: name, ring: loops[0], holes: Array(loops.dropFirst()))
    }
}

func apple(_ a: Point, _ b: Point) async -> (minutes: Double, km: Double)? {
    let request = MKDirections.Request()
    request.source = MKMapItem(placemark: MKPlacemark(coordinate: .init(latitude: a.lat, longitude: a.lon)))
    request.destination = MKMapItem(placemark: MKPlacemark(coordinate: .init(latitude: b.lat, longitude: b.lon)))
    request.transportType = .automobile
    try? await Task.sleep(for: .seconds(1.3))
    guard let r = try? await MKDirections(request: request).calculate().routes.first else { return nil }
    return (r.expectedTravelTime / 60, r.distance / 1000)
}

func ms(_ start: ContinuousClock.Instant) -> Int {
    let d = start.duration(to: .now).components
    return Int(d.seconds * 1000 + d.attoseconds / 1_000_000_000_000_000)
}

struct RouteRecord: Encodable { let label: String; let city: String; let nodes: [Int] }
var records: [RouteRecord] = []

@MainActor func run(city: String, zoneSet: String, trips: [Trip], calibrate: Bool) async throws {
    let t0 = ContinuousClock.now
    let graph = try Graph(contentsOf: base.appendingPathComponent("\(city).bin"))
    let loadMs = ms(t0)
    let area = try zones(zoneSet)
    let t1 = ContinuousClock.now
    let blocked = graph.blockedNodes(zones: area)
    print("\n## \(zoneSet): \(graph.nodeCount) nodi, \(area.count) poligoni, caricamento \(loadMs) ms, blocco zone \(ms(t1)) ms, nodi bloccati \(blocked.filter { $0 }.count)\n")
    print("| Tragitto | Apple: min, km | Grafo libero: min, km | Libero: m in zona | Evita: min, km | m in zona | Extra | A* ms | Valido |")
    print("|---|---|---|---|---|---|---|---|---|")
    var valid = 0
    for trip in trips {
        let starts = graph.nearest(to: trip.from, count: 40)
        let from = starts[0]
        let inside = area.contains { $0.contains(trip.to) }
        let goals = graph.nearest(to: trip.to, count: 40) { blocked[$0] }
        let free = graph.route(from: from, to: graph.nearest(to: trip.to)[0])
        let t = ContinuousClock.now
        var found: Graph.Path?
        search: for start in starts {
            for goal in goals.prefix(10) {
                found = graph.route(from: start, to: goal, blocked: blocked)
                if found != nil { break search }
            }
        }
        let elapsed = ms(t)
        let a = calibrate ? await apple(trip.from, trip.to) : nil
        let appleText = a.map { "\(Int($0.minutes)), \(String(format: "%.1f", $0.km))" } ?? "-"
        let freeText = free.map { "\(Int($0.seconds / 60)), \(String(format: "%.1f", $0.metres / 1000))" } ?? "-"
        guard let found, let free else {
            print("| \(trip.name) | \(appleText) | \(freeText) | - | nessun percorso | - | - | \(elapsed) | no |")
            continue
        }
        let points = found.nodes.map(graph.point)
        // Independent of the blocking logic: the same geometric check spike 1 used, zone by zone.
        let metresIn = metresInside(area, route: points)
        let freeIn = Int(metresInside(area, route: free.nodes.map(graph.point)))
        let extra = found.seconds - free.seconds
        let ok = metresIn < 1 && (found.seconds <= free.seconds * 1.5 || extra <= 600)
        if ok { valid += 1 }
        let walk = graph.point(found.nodes.last!).metres(to: trip.to)
        let note = inside ? " (a piedi \(Int(walk)) m)" : ""
        print("| \(trip.name)\(note) | \(appleText) | \(freeText) | \(freeIn) | \(Int(found.seconds / 60)), \(String(format: "%.1f", found.metres / 1000)) | \(Int(metresIn)) | +\(Int(extra / 60)) min | \(elapsed) | \(ok ? "sì" : "no") |")
        records.append(RouteRecord(label: "\(zoneSet) \(trip.name)", city: city, nodes: found.nodes))
    }
    print("\nValidi: \(valid)/\(trips.count)")
}

try await run(city: "milano", zoneSet: "milano-c", trips: milanoTrips, calibrate: true)
try await run(city: "firenze", zoneSet: "firenze", trips: firenzeTrips, calibrate: true)
try await run(city: "milano", zoneSet: "milano-tutte", trips: milanoTrips, calibrate: false)
try JSONEncoder().encode(records).write(to: URL(fileURLWithPath: CommandLine.arguments[2]))
