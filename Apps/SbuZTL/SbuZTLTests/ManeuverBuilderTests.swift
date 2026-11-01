import Testing
@testable import SbuZTL

struct ManeuverBuilderTests {
    @Test("Heading changes name the turn", arguments: [
        (0.0, Maneuver.straight), (-90, .left), (90, .right), (-40, .slightLeft), (40, .slightRight), (-140, .sharpLeft), (140, .sharpRight), (175, .uTurn),
    ])
    func turn(degrees: Double, expected: Maneuver) {
        #expect(Maneuver.turn(degrees: degrees) == expected)
    }

    @Test("A corner on the grid is a named turn, and the route ends with arriving")
    func steps() throws {
        let graph = GraphFixture.grid()
        // North along column 0, then east along row 2.
        let path = Graph.Path(nodes: [0, 3, 6, 7], edges: try [edge(graph, 0, 3), edge(graph, 3, 6), edge(graph, 6, 7)], seconds: 30, metres: 300)
        let steps = ManeuverBuilder.steps(graph: graph, path: path)
        #expect(steps.map(\.maneuver) == [.depart, .right, .arrive])
        #expect(steps[1].street == "Via Est")
        #expect(steps[1].startMetre == 200)
        #expect(steps[2].startMetre == 300)
    }

    private func edge(_ graph: Graph, _ a: Int, _ b: Int) throws -> Int {
        try #require((Int(graph.first[a])..<Int(graph.first[a + 1])).first { graph.to[$0] == Int32(b) })
    }
}
