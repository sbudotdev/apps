import Foundation
import Testing
@testable import SbuZTL

struct RoutePlannerTests {
    private struct NoApproach: ApproachRouter {
        func leg(from start: Point, to end: Point) async throws -> ApproachLeg { throw RouteError.noRoute }
    }

    private struct LineApproach: ApproachRouter {
        func leg(from start: Point, to end: Point) async throws -> ApproachLeg {
            let points = (0...40).map { Point(start.lat + (end.lat - start.lat) * Double($0) / 40, start.lon + (end.lon - start.lon) * Double($0) / 40) }
            return ApproachLeg(points: points, seconds: 1800, steps: [ApproachStep(instruction: "Prosegui", startMetre: 0)])
        }
    }

    private func planner(_ zones: [Zone], approach: any ApproachRouter = NoApproach(), city: City = .milano) -> RoutePlanner {
        let store = GraphStore()
        return RoutePlanner(catalog: ZoneCatalog(zones: zones), graphs: { try await store.graph(for: $0) }, approach: approach)
    }

    private func request(from: Point, to: Point, vehicle: Vehicle? = nil, avoidsPaid: Bool = true, departure: Date = RuleEngineTests.monday) -> RouteRequest {
        RouteRequest(start: from, destination: to, vehicle: vehicle ?? RuleEngineTests.car(.petrol, .euro5),
                     departure: departure, permits: [], avoidsPaidZones: avoidsPaid)
    }

    private static let bicocca = Point(45.5140, 9.2100)
    private static let bocconi = Point(45.4490, 9.1900)
    private static let duomo = Point(45.4642, 9.1900)
    private static let trezzano = Point(45.4200, 9.0400)

    @Test("Across Milan the route stays out of Area C and its streets")
    func avoidsAreaC() async throws {
        let catalog = ZoneCatalog.bundled
        let plan = try await planner(catalog.zones).plan(request(from: Self.bicocca, to: Self.bocconi))
        let areaC = try #require(catalog.zones.first { $0.kind == .areaC })
        #expect(!plan.points.contains { areaC.contains($0) })
        #expect(plan.walkMetres == nil)
        #expect(plan.steps.last?.maneuver == .arrive)
        #expect(plan.steps.contains { $0.street != nil })
    }

    @Test("A destination in a closed zone leaves you at its edge, on foot")
    func destinationInside() async throws {
        let plan = try await planner(ZoneCatalog.bundled.zones).plan(request(from: Self.bicocca, to: Self.duomo))
        #expect(plan.destinationZone != nil)
        let walk = try #require(plan.walkMetres)
        #expect(walk > 0)
    }

    @Test("A start outside the graph uses Apple's stretch and says part isn't covered")
    func approach() async throws {
        let plan = try await planner(ZoneCatalog.bundled.zones, approach: LineApproach()).plan(request(from: Self.trezzano, to: Self.bocconi))
        #expect(plan.isPartlyUncovered)
        #expect(plan.steps.first?.instruction == "Prosegui")
        #expect(plan.cumulative == plan.cumulative.sorted())
    }

    @Test("A destination outside coverage is Apple's route, flagged")
    func outside() async throws {
        let plan = try await planner(ZoneCatalog.bundled.zones, approach: LineApproach()).plan(request(from: Self.bocconi, to: Point(40.85, 14.27))) // Napoli
        #expect(plan.isPartlyUncovered)
    }

    @Test("Paying your way lets the route through Area C when chosen")
    func paidAllowed() async throws {
        let areaC = try #require(ZoneCatalog.bundled.zones.first { $0.kind == .areaC })
        let avoiding = try await planner([areaC]).plan(request(from: Self.bicocca, to: Self.duomo))
        let paying = try await planner([areaC]).plan(request(from: Self.bicocca, to: Self.duomo, avoidsPaid: false))
        // The Duomo's square has no road, so paying still ends with a short walk: only the zone changes.
        #expect(avoiding.destinationZone == "Area C")
        #expect(paying.destinationZone == nil)
    }

    @Test("Bologna: across the centre the route stays out of the ZTL")
    func bologna() async throws {
        let catalog = ZoneCatalog.bundled
        let ztl = try #require(catalog.zones(in: .bologna).first { $0.kind == .bolognaZtl })
        let plan = try await planner(catalog.zones(in: .bologna)).plan(request(from: Point(44.5080, 11.3430), to: Point(44.4800, 11.3400)))
        #expect(!plan.points.contains { ztl.contains($0) })
        #expect(plan.steps.last?.maneuver == .arrive)
    }

    @Test("Roma: across the centre the route stays out of the ZTL in its hours")
    func roma() async throws {
        let catalog = ZoneCatalog.bundled
        let centro = try #require(catalog.zones(in: .roma).first { $0.kind == .romaCentroDay })
        let plan = try await planner(catalog.zones(in: .roma)).plan(request(from: Point(41.9090, 12.5010), to: Point(41.8870, 12.4580)))
        #expect(!plan.points.contains { centro.contains($0) })
        #expect(plan.steps.last?.maneuver == .arrive)
    }

    @Test("Torino: across the centre the route stays out of the ZTL in its hours")
    func torino() async throws {
        let catalog = ZoneCatalog.bundled
        let centrale = try #require(catalog.zones(in: .torino).first)
        let plan = try await planner(catalog.zones(in: .torino)).plan(request(
            from: Point(45.0640, 7.6600), to: Point(45.0620, 7.7050), departure: RuleEngineTests.moment(2026, 11, 2, 9)))
        #expect(!plan.points.contains { centrale.contains($0) })
        #expect(plan.steps.last?.maneuver == .arrive)
    }
}
