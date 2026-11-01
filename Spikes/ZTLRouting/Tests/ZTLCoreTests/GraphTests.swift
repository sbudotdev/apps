import Testing
@testable import ZTLCore

struct GraphTests {
    // 0 -> 1 -> 2 is the short way, 0 -> 3 -> 2 the long one; 1 -> 0 doesn't exist, the edges are one-way.
    let graph = Graph(
        lat: [45, 45, 45, 45.01],
        lon: [9, 9.01, 9.02, 9.01],
        first: [0, 2, 3, 3, 4],
        to: [1, 3, 2, 2],
        seconds: [60, 200, 60, 200],
        metres: [800, 1500, 800, 1500])

    @Test func picksTheFastestPath() throws {
        let path = try #require(graph.route(from: 0, to: 2))
        #expect(path.nodes == [0, 1, 2])
        #expect(path.seconds == 120)
        #expect(path.metres == 1600)
    }

    @Test func respectsOneWay() {
        #expect(graph.route(from: 2, to: 0) == nil)
    }

    @Test func goesAroundABlockedNode() throws {
        let path = try #require(graph.route(from: 0, to: 2, blocked: [false, true, false, false]))
        #expect(path.nodes == [0, 3, 2])
    }

    @Test func noRouteWhenEveryWayIsBlocked() {
        #expect(graph.route(from: 0, to: 2, blocked: [false, true, false, true]) == nil)
    }

    @Test func aStartInsideCanLeave() throws {
        let path = try #require(graph.route(from: 1, to: 2, blocked: [false, true, false, false]))
        #expect(path.nodes == [1, 2])
    }

    @Test func aBannedTurnForcesTheOtherWay() throws {
        let banned = Graph(
            lat: graph.lat, lon: graph.lon, first: [0, 2, 3, 3, 4], to: [1, 3, 2, 2],
            seconds: [60, 200, 60, 200], metres: [800, 1500, 800, 1500],
            bannedTurns: [Turn(from: 0, via: 1, to: 2)])
        let path = try #require(banned.route(from: 0, to: 2))
        #expect(path.nodes == [0, 3, 2])
    }

    @Test func secondsStayRealWhenLeavingAZone() throws {
        let path = try #require(graph.route(from: 1, to: 2, blocked: [false, true, true, false]))
        #expect(path.seconds == 60)
    }

    @Test func zoneHoleIsOutside() {
        let zone = Zone(
            name: "ring",
            ring: [Point(44, 8), Point(44, 10), Point(46, 10), Point(46, 8)],
            holes: [[Point(44.9, 8.9), Point(44.9, 9.1), Point(45.1, 9.1), Point(45.1, 8.9)]])
        #expect(!zone.contains(Point(45, 9)))
        #expect(zone.contains(Point(44.5, 9)))
    }
}
