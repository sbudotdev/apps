// Throwaway: can MKDirections alone avoid a ZTL? Perimeters are hand-approximated, not official data.
import Foundation
@preconcurrency import MapKit
import ZTLCore

struct Trip { let name: String; let from: Point; let to: Point }
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

let centrale = Point(45.4862, 9.2044), bocconi = Point(45.4490, 9.1900)
let duomoMI = Point(45.4642, 9.1900), brera = Point(45.4719, 9.1880), castello = Point(45.4705, 9.1794)
let areaC = Zone(name: "Milano Area C", ring: [
    Point(45.4797, 9.1977), Point(45.4745, 9.2055), Point(45.4626, 9.2069), Point(45.4545, 9.2045),
    Point(45.4517, 9.2000), Point(45.4520, 9.1815), Point(45.4541, 9.1719), Point(45.4600, 9.1690),
    Point(45.4673, 9.1675), Point(45.4757, 9.1725), Point(45.4815, 9.1825), Point(45.4810, 9.1900),
])
let milano = [
    Trip(name: "Centrale-Porta Genova", from: centrale, to: Point(45.4533, 9.1680)),
    Trip(name: "Sempione-Porta Romana", from: Point(45.4790, 9.1690), to: Point(45.4490, 9.2030)),
    Trip(name: "Loreto-Bocconi", from: Point(45.4859, 9.2160), to: bocconi),
    Trip(name: "Lambrate-San Siro", from: Point(45.4847, 9.2365), to: Point(45.4781, 9.1240)),
    Trip(name: "Cinque Giornate-Conciliazione", from: Point(45.4626, 9.2120), to: Point(45.4671, 9.1635)),
    Trip(name: "Porta Venezia-Ticinese", from: Point(45.4765, 9.2085), to: Point(45.4495, 9.1815)),
    Trip(name: "Centrale-Duomo (arrivo dentro)", from: centrale, to: duomoMI),
    Trip(name: "Bocconi-Castello (arrivo dentro)", from: bocconi, to: castello),
    Trip(name: "Duomo-Centrale (partenza dentro)", from: duomoMI, to: centrale),
    Trip(name: "Brera-Bocconi (partenza dentro)", from: brera, to: bocconi),
]

let campoMarte = Point(43.7833, 11.2825), novoli = Point(43.7960, 11.2190), duomoFI = Point(43.7731, 11.2560)
let centroFI = Zone(name: "Firenze ZTL Centro", ring: [
    Point(43.7825, 11.2490), Point(43.7830, 11.2620), Point(43.7775, 11.2665), Point(43.7695, 11.2680),
    Point(43.7635, 11.2670), Point(43.7610, 11.2650), Point(43.7620, 11.2610), Point(43.7585, 11.2420),
    Point(43.7705, 11.2350), Point(43.7725, 11.2365), Point(43.7785, 11.2410),
])
let firenze = [
    Trip(name: "Campo di Marte-Porta Romana", from: campoMarte, to: Point(43.7560, 11.2400)),
    Trip(name: "Dalmazia-Ferrucci", from: Point(43.7930, 11.2430), to: Point(43.7585, 11.2700)),
    Trip(name: "Le Cure-Soffiano", from: Point(43.7900, 11.2660), to: Point(43.7600, 11.2200)),
    Trip(name: "Novoli-Gavinana", from: novoli, to: Point(43.7550, 11.2750)),
    Trip(name: "Cascine-Beccaria", from: Point(43.7810, 11.2200), to: Point(43.7690, 11.2720)),
    Trip(name: "Libertà-San Frediano", from: Point(43.7860, 11.2620), to: Point(43.7710, 11.2300)),
    Trip(name: "Campo di Marte-Duomo (arrivo dentro)", from: campoMarte, to: duomoFI),
    Trip(name: "Novoli-Santa Croce (arrivo dentro)", from: novoli, to: Point(43.7686, 11.2622)),
    Trip(name: "Duomo-Novoli (partenza dentro)", from: duomoFI, to: novoli),
    Trip(name: "Santo Spirito-Campo di Marte (partenza dentro)", from: Point(43.7675, 11.2480), to: campoMarte),
]

_ = await run(zone: areaC, trips: milano)
_ = await run(zone: centroFI, trips: firenze)
