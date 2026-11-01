// Throwaway: can MKDirections alone avoid a ZTL? Perimeters are hand-approximated, not official data.
import Foundation
@preconcurrency import MapKit
import ZTLCore

struct Found { let points: [Point]; let seconds: Double }

let toleranceMetres = 150.0 // the hand-drawn perimeter is only good to about this

func route(_ a: Point, _ b: Point, alternates: Bool = false) async throws -> [Found] {
    let request = MKDirections.Request()
    request.source = MKMapItem(placemark: MKPlacemark(coordinate: .init(latitude: a.lat, longitude: a.lon)))
    request.destination = MKMapItem(placemark: MKPlacemark(coordinate: .init(latitude: b.lat, longitude: b.lon)))
    request.transportType = .automobile
    request.requestsAlternateRoutes = alternates
    for attempt in 0..<3 {
        try await Task.sleep(for: .seconds(1.3))
        do {
            let response = try await MKDirections(request: request).calculate()
            return response.routes.map { r in
                let line = r.polyline
                let points = UnsafeBufferPointer(start: line.points(), count: line.pointCount).map {
                    Point($0.coordinate.latitude, $0.coordinate.longitude)
                }
                return Found(points: points, seconds: r.expectedTravelTime)
            }
        } catch let error as MKError where error.code == .loadingThrottled && attempt < 2 {
            try await Task.sleep(for: .seconds(65))
        }
    }
    return []
}

func chain(_ stops: [Point]) async throws -> Found? {
    var points: [Point] = []
    var seconds = 0.0
    for (a, b) in zip(stops, stops.dropFirst()) {
        guard let leg = try await route(a, b).first else { return nil }
        points += leg.points
        seconds += leg.seconds
    }
    return Found(points: points, seconds: seconds)
}

func run(zone: Zone, trips: [Trip]) async -> (valid: Int, total: Int) {
    var valid = 0
    print("\n## \(zone.name) (perimetro approssimato a mano)\n")
    print("| Tragitto | Base: min, m in zona | Metodo | Scelto: min, m in zona | Extra | Valido |")
    print("|---|---|---|---|---|---|")
    for trip in trips {
        do {
            let destinationInside = zone.contains(trip.to)
            let target = destinationInside ? zone.nearestOuterPoint(to: trip.to) : trip.to
            guard let base = try await route(trip.from, trip.to).first else {
                print("| \(trip.name) | nessun percorso | - | - | - | no |"); continue
            }
            let baseInside = zone.metresInside(route: base.points)
            var method = "alternativa"
            var best = try await route(trip.from, target, alternates: true)
                .filter { zone.metresInside(route: $0.points) < toleranceMetres }
                .min { $0.seconds < $1.seconds }
            if best == nil {
                method = "tappe"
                for way in zone.detours(from: trip.from, to: target, limit: 100) {
                    guard let candidate = try await chain([trip.from] + way + [target]) else { continue }
                    let inside = zone.metresInside(route: candidate.points)
                    print("<!-- \(trip.name): \(way.count) tappe, \(Int(inside)) m in zona, \(Int(candidate.seconds / 60)) min -->")
                    guard inside < toleranceMetres else { continue }
                    if best == nil || candidate.seconds < best!.seconds { best = candidate }
                }
            }
            guard let best else {
                print("| \(trip.name) | \(Int(base.seconds / 60)), \(Int(baseInside)) | fallito | - | - | no |"); continue
            }
            // Fixed before the first run: at most +50% or +10 minutes over the unrestricted route.
            let extra = best.seconds - base.seconds
            let ok = best.seconds <= base.seconds * 1.5 || extra <= 600
            if ok { valid += 1 }
            let note = destinationInside ? " (arrivo sul bordo)" : ""
            print("| \(trip.name) | \(Int(base.seconds / 60)), \(Int(baseInside)) | \(method)\(note) | \(Int(best.seconds / 60)), \(Int(zone.metresInside(route: best.points))) | +\(Int(extra / 60)) min | \(ok ? "sì" : "no") |")
        } catch {
            print("| \(trip.name) | errore: \(error.localizedDescription) | - | - | - | no |")
        }
    }
    print("\nValidi: \(valid)/\(trips.count)")
    return (valid, trips.count)
}

let areaC = Zone(name: "Milano Area C", ring: [
    Point(45.4797, 9.1977), Point(45.4745, 9.2055), Point(45.4626, 9.2069), Point(45.4545, 9.2045),
    Point(45.4517, 9.2000), Point(45.4520, 9.1815), Point(45.4541, 9.1719), Point(45.4600, 9.1690),
    Point(45.4673, 9.1675), Point(45.4757, 9.1725), Point(45.4815, 9.1825), Point(45.4810, 9.1900),
])
let centroFI = Zone(name: "Firenze ZTL Centro", ring: [
    Point(43.7825, 11.2490), Point(43.7830, 11.2620), Point(43.7775, 11.2665), Point(43.7695, 11.2680),
    Point(43.7635, 11.2670), Point(43.7610, 11.2650), Point(43.7620, 11.2610), Point(43.7585, 11.2420),
    Point(43.7705, 11.2350), Point(43.7725, 11.2365), Point(43.7785, 11.2410),
])
_ = await run(zone: areaC, trips: milanoTrips)
_ = await run(zone: centroFI, trips: firenzeTrips)
