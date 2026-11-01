import MapKit
import Observation
import SbuKit
import SwiftUI

/// The map's state: what's selected, for which moment, and the route being planned.
@Observable
final class MapModel {
    var phase = MapPhase.home
    /// `nil` is now.
    var departure: Date?
    var camera: MapCameraPosition = .region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 42.5, longitude: 12.5), span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)))
    var showsZones = true
    var problem: LocalizedStringKey?
    #if DEBUG
    /// The last route's computing time, for the numbers of the device test (#628).
    var planTime: Duration?
    #endif
    let store: AppStore
    let location: LocationService
    let catalog: ZoneCatalog
    private let planner: RoutePlanner
    private var planning: Task<Void, Never>?

    init(store: AppStore, location: LocationService, catalog: ZoneCatalog = .bundled, approach: any ApproachRouter = MapKitApproachRouter()) {
        self.store = store
        self.location = location
        self.catalog = catalog
        let graphs = GraphStore()
        planner = RoutePlanner(catalog: catalog, graphs: { try await graphs.graph(for: $0) }, approach: approach)
    }

    var moment: Date { departure ?? .now }

    /// Dragging the map stops following: the guide offers the way back.
    var isCameraDetached: Bool { camera.positionedByUser }

    func select(_ place: Place) {
        store.remember(place)
        show(place)
    }

    /// The first-run tour's example: not among your recent places.
    func showExample() {
        show(Place(name: String(localized: "Duomo di Milano"), address: "Milano", point: Point(45.4642, 9.1900)))
    }

    private func show(_ place: Place) {
        phase = .place(place)
        withAnimation(SbuMotion.base) {
            camera = .region(MKCoordinateRegion(center: place.point.coordinate, latitudinalMeters: 700, longitudinalMeters: 700))
        }
    }

    /// The tap on the map: a place named after the zone under the finger, if any.
    func selectPoint(_ point: Point) {
        guard case .home = phase else { return }
        let zones = catalog.zones(at: point).filter { $0.kind != .areaB }
        select(Place(name: zones.first?.name ?? String(localized: "Punto sulla mappa"), address: "", point: point))
    }

    func verdicts(at point: Point) -> [(zone: Zone, verdict: Verdict)] {
        catalog.zones(at: point).map { ($0, RuleEngine.verdict(zone: $0, vehicle: store.vehicle, at: moment, permits: store.state.permits)) }
    }

    func plan(to place: Place) {
        planning?.cancel()
        phase = .planning(place)
        planning = Task { await computePlan(to: place) }
    }

    func cancelPlanning(back place: Place) {
        planning?.cancel()
        phase = .place(place)
    }

    private func computePlan(to place: Place) async {
        guard let fix = await location.currentFix() else {
            problem = location.isDenied ? "Permetti la posizione nelle Impostazioni per calcolare il percorso." : "Non trovo la tua posizione. Riprova tra poco."
            phase = .place(place)
            return
        }
        do {
            let clock = ContinuousClock()
            let began = clock.now
            let result = try await planner.plan(request(from: fix.point, to: place.point))
            #if DEBUG
            planTime = began.duration(to: clock.now)
            #else
            _ = began
            #endif
            guard !Task.isCancelled else { return }
            phase = .preview(place, result)
            fit(result)
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
            problem = "Non trovo un percorso che rispetti le zone. Controlla veicolo e orario, o scegli un altro arrivo."
            phase = .place(place)
        }
    }

    private func request(from start: Point, to destination: Point) -> RouteRequest {
        RouteRequest(start: start, destination: destination, vehicle: store.vehicle, departure: moment,
                     permits: store.state.permits, avoidsPaidZones: store.state.avoidsPaidZones)
    }

    private func fit(_ plan: RoutePlan) {
        let points = plan.points.map { MKMapPoint($0.coordinate) }
        guard let first = points.first else { return }
        var rect = MKMapRect(origin: first, size: MKMapSize(width: 1, height: 1))
        for point in points { rect = rect.union(MKMapRect(origin: point, size: MKMapSize(width: 1, height: 1))) }
        withAnimation(SbuMotion.base) {
            camera = .rect(rect.insetBy(dx: -rect.width * 0.15, dy: -rect.height * 0.15))
        }
    }

    func start(_ plan: RoutePlan, to place: Place) {
        departure = nil
        let destination = place.point
        let guidance = GuidanceModel(plan: plan, speaks: store.state.speaks) { [weak self] from in
            guard let self else { throw RouteError.noRoute }
            return try await self.planner.plan(self.request(from: from, to: destination))
        }
        phase = .guiding(place, guidance)
        followUser()
    }

    func followUser() {
        withAnimation(SbuMotion.base) {
            camera = .userLocation(followsHeading: !store.state.keepsNorthUp, fallback: .automatic)
        }
    }

    func close() {
        planning?.cancel()
        phase = .home
    }
}
