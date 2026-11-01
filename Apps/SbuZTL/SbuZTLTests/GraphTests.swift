import Testing
@testable import SbuZTL

struct GraphTests {
    @Test("The shortest route between opposite corners")
    func shortest() throws {
        let path = try #require(GraphFixture.grid().route(from: 0, to: 8))
        #expect(path.edges.count == 4)
        #expect(path.metres == 400)
    }

    @Test("A blocked node is never entered")
    func avoidsBlocked() throws {
        var blocked = [Bool](repeating: false, count: 9)
        blocked[4] = true
        let path = try #require(GraphFixture.grid().route(from: 1, to: 7, blocked: blocked))
        #expect(!path.nodes.contains(4))
    }

    @Test("A route can leave the zone it starts in")
    func leavesStartZone() throws {
        var blocked = [Bool](repeating: false, count: 9)
        blocked[4] = true
        let path = try #require(GraphFixture.grid().route(from: 4, to: 8, blocked: blocked))
        #expect(path.nodes.first == 4)
        #expect(path.nodes.last == 8)
    }

    @Test("No route when the zone closes the goal off")
    func closedGoal() {
        var blocked = [Bool](repeating: false, count: 9)
        blocked[5] = true
        blocked[7] = true
        #expect(GraphFixture.grid().route(from: 0, to: 8, blocked: blocked) == nil)
    }

    @Test("A banned turn is not taken")
    func bannedTurn() throws {
        let free = try #require(GraphFixture.grid().route(from: 0, to: 2))
        #expect(free.nodes == [0, 1, 2])
        let banned = Turn(from: 0, via: 1, to: 2)
        let path = try #require(GraphFixture.grid(banned: [banned]).route(from: 0, to: 2))
        #expect(path.nodes != [0, 1, 2])
    }

    @Test("Bundled graphs load with names and limits", arguments: [City.milano, .firenze])
    func bundled(city: City) async throws {
        let graph = try await GraphStore().graph(for: city)
        #expect(graph.nodeCount > 50_000)
        #expect(graph.names.count > 1_000)
        #expect(graph.limit.contains { $0 > 0 })
    }
}
