import Testing
@testable import ZTLCore

struct ZoneTests {
    // About 2.2 km a side around (45, 9).
    let zone = Zone(name: "square", ring: [Point(44.99, 8.99), Point(44.99, 9.01), Point(45.01, 9.01), Point(45.01, 8.99)])

    @Test func containsCentreNotOutside() {
        #expect(zone.contains(Point(45, 9)))
        #expect(!zone.contains(Point(45.02, 9)))
    }

    @Test func routeAroundIsClean() {
        let route = [Point(44.98, 8.98), Point(44.98, 9.02), Point(45.02, 9.02)]
        #expect(zone.metresInside(route: route) == 0)
    }

    @Test func routeThroughCountsTheCrossing() {
        let inside = zone.metresInside(route: [Point(45, 8.98), Point(45, 9.02)])
        #expect(abs(inside - 1575) < 60)
    }

    @Test func startInsideCountsOnlyAfterLeaving() {
        #expect(zone.metresInside(route: [Point(45, 9), Point(45, 9.02)]) == 0)
        let backIn = zone.metresInside(route: [Point(45, 9), Point(45, 9.02), Point(45, 9)])
        #expect(backIn > 500)
    }

    @Test func detoursStayOutsideAndGoBothWays() {
        let ways = zone.detours(from: Point(45, 8.98), to: Point(45, 9.02))
        #expect(ways.count == 2)
        #expect(ways.allSatisfy { $0.allSatisfy { !zone.contains($0) } })
        #expect(ways[0] != ways[1])
    }

    @Test func destinationInsideMovesOutside() {
        #expect(!zone.contains(zone.nearestOuterPoint(to: Point(45, 9))))
    }
}
