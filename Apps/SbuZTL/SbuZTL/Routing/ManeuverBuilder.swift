import Foundation

/// Turns a graph path into instructions, from headings and street names.
/// shortcut: roundabouts read as plain turns; OSM junction tags aren't in the graph yet, add them after the road test.
nonisolated enum ManeuverBuilder {
    /// Below this angle a road that only bends isn't a turn.
    private static let turnThreshold = 25.0

    static func steps(graph: Graph, path: Graph.Path, startMetre: Double = 0) -> [RouteStep] {
        guard let firstEdge = path.edges.first else {
            return [RouteStep(maneuver: .arrive, street: nil, startMetre: startMetre, instruction: nil)]
        }
        var steps = [RouteStep(maneuver: .depart, street: name(graph, firstEdge), startMetre: startMetre, instruction: nil)]
        var run = startMetre + Double(graph.metres[firstEdge])
        for i in 1..<max(path.edges.count, 1) where path.edges.count > 1 {
            let before = path.edges[i - 1], edge = path.edges[i]
            let via = path.nodes[i]
            let degrees = headingChange(graph.point(path.nodes[i - 1]), graph.point(via), graph.point(path.nodes[i + 1]))
            let exits = Int(graph.first[via + 1]) - Int(graph.first[via])
            let renamed = graph.nameIndex[before] != graph.nameIndex[edge]
            if abs(degrees) >= turnThreshold, exits > 1 || renamed {
                steps.append(RouteStep(maneuver: Maneuver.turn(degrees: degrees), street: name(graph, edge), startMetre: run, instruction: nil))
            } else if renamed, name(graph, edge) != nil {
                steps.append(RouteStep(maneuver: .straight, street: name(graph, edge), startMetre: run, instruction: nil))
            }
            run += Double(graph.metres[edge])
        }
        steps.append(RouteStep(maneuver: .arrive, street: nil, startMetre: run, instruction: nil))
        return steps
    }

    private static func name(_ graph: Graph, _ edge: Int) -> String? {
        let name = graph.names[Int(graph.nameIndex[edge])]
        return name.isEmpty ? nil : name
    }

    /// In -180...180, negative to the left.
    static func headingChange(_ a: Point, _ b: Point, _ c: Point) -> Double {
        let change = b.bearing(to: c) - a.bearing(to: b)
        return change > 180 ? change - 360 : change < -180 ? change + 360 : change
    }
}
