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

    private func request(from: Point, to: Point, vehicle: Vehicle? = nil, avoidsPaid: Bool = true) -> RouteRequest {
        RouteRequest(start: from, destination: to, vehicle: vehicle ?? RuleEngineTests.car(.petrol, .euro5),
                     departure: RuleEngineTests.monday, permits: [], avoidsPaidZones: avoidsPaid)
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
        let plan = try await planner(ZoneCatalog.bundled.zones, approach: LineApproach()).plan(request(from: Self.bocconi, to: Point(41.9, 12.5)))
        #expect(plan.isPartlyUncovered)
    }

    @Test("Paying your way lets the route through Area C when chosen")
    func paidAllowed() async throws {
        let areaC = try #require(ZoneCatalog.bundled.zones.first { $0.kind == .areaC })
        let avoiding = try await planner([areaC]).plan(request(from: Self.bicocca, to: Self.duomo))
        let paying = try await planner([areaC]).plan(request(from: Self.bicocca, to: Self.duomo, avoidsPaid: false))
        #expect(avoiding.walkMetres != nil)
        #expect(paying.walkMetres == nil)
    }
}
