import Foundation

/// Plans a trip: the graph where we have one, Apple's directions up to its edge.
nonisolated struct RoutePlanner: Sendable {
    /// shortcut: the graph underestimates urban times, mostly at traffic lights. Replace with GPS-calibrated values (#658).
    static let etaFactor = 1.4
    /// How far ahead a zone's hours matter, for one that opens during the trip.
    private static let horizon: TimeInterval = 45 * 60
    /// Beyond this the end of the road is worth a word, even with no zone around.
    private static let walkThreshold = 80.0

    let catalog: ZoneCatalog
    let graphs: @Sendable (City) async throws -> Graph
    let approach: any ApproachRouter

    func plan(_ request: RouteRequest) async throws -> RoutePlan {
        guard let city = catalog.city(at: request.destination) else {
            return try await appleOnly(request)
        }
        let graph = try await graphs(city)
        let closed = closedZones(city: city, request: request)
        let blocked = graph.blockedNodes(polygons: closed.flatMap(\.polygons))
        try Task.checkCancellation()

        let destinationZone = closed.first { $0.contains(request.destination) }?.name
        let goals = graph.nearest(to: request.destination, count: 20) { blocked[$0] }
        guard !goals.isEmpty else { throw RouteError.noRoute }

        var prefix: ApproachLeg?
        var startPoint = request.start
        if !graph.covers(request.start) {
            let leg = try await approach.leg(from: request.start, to: request.destination)
            guard let entry = entryIndex(leg.points, graph: graph, closed: closed) else { throw RouteError.noRoute }
            prefix = trimmed(leg, to: entry)
            startPoint = leg.points[entry]
        }
        let startZone = prefix == nil ? closed.first { $0.contains(startPoint) }?.name : nil
        let starts = graph.nearest(to: startPoint, count: 20)
        guard let path = search(graph, starts: starts, goals: goals, blocked: blocked) else { throw RouteError.noRoute }
        try Task.checkCancellation()

        let end = graph.point(path.nodes[path.nodes.count - 1])
        let walk = request.destination.metres(to: end)
        return assemble(graph: graph, path: path, prefix: prefix, request: request,
                        walkMetres: destinationZone != nil || walk > Self.walkThreshold ? walk : nil,
                        destinationZone: destinationZone, startZone: startZone)
    }

    private func closedZones(city: City, request: RouteRequest) -> [Zone] {
        let later = request.departure.addingTimeInterval(Self.horizon)
        return catalog.zones(in: city).filter { zone in
            [request.departure, later].contains { moment in
                RuleEngine.verdict(zone: zone, vehicle: request.vehicle, at: moment, permits: request.permits)
                    .access.avoided(avoidingPaid: request.avoidsPaidZones)
            }
        }
    }

    private func search(_ graph: Graph, starts: [Int], goals: [Int], blocked: [Bool]) -> Graph.Path? {
        for start in starts {
            for goal in goals.prefix(5) {
                if let path = graph.route(from: start, to: goal, blocked: blocked) { return path }
            }
        }
        return nil
    }

    /// The first point of Apple's route inside the graph and outside every closed zone.
    private func entryIndex(_ points: [Point], graph: Graph, closed: [Zone]) -> Int? {
        points.firstIndex { p in graph.covers(p) && !closed.contains { $0.contains(p) } }
    }

    private func trimmed(_ leg: ApproachLeg, to index: Int) -> ApproachLeg {
        let points = Array(leg.points[...index])
        var length = 0.0
        for (a, b) in zip(points, points.dropFirst()) { length += a.metres(to: b) }
        let total = zip(leg.points, leg.points.dropFirst()).reduce(0) { $0 + $1.0.metres(to: $1.1) }
        return ApproachLeg(points: points, seconds: total > 0 ? leg.seconds * length / total : 0,
                           steps: leg.steps.filter { $0.startMetre < length })
    }

    private func assemble(graph: Graph, path: Graph.Path, prefix: ApproachLeg?, request: RouteRequest,
                          walkMetres: Double?, destinationZone: String?, startZone: String?) -> RoutePlan {
        var points = prefix?.points ?? []
        var limits = [Int](repeating: 0, count: points.count)
        var cumulative: [Double] = []
        var run = 0.0
        for (i, p) in points.enumerated() {
            if i > 0 { run += points[i - 1].metres(to: p) }
            cumulative.append(run)
        }
        let joint = run
        var steps = prefix?.steps.map { RouteStep(maneuver: .straight, street: nil, startMetre: $0.startMetre, instruction: $0.instruction) } ?? []
        steps += ManeuverBuilder.steps(graph: graph, path: path, startMetre: joint)
        for (i, node) in path.nodes.enumerated() {
            let p = graph.point(node)
            if let last = points.last { run += last.metres(to: p) }
            points.append(p)
            cumulative.append(run)
            limits.append(i < path.edges.count ? Int(graph.limit[path.edges[i]]) : 0)
        }
        // A jump between Apple's last point and the first node would otherwise count as driving.
        return RoutePlan(points: points, cumulative: cumulative, steps: steps, limits: limits,
                         seconds: path.seconds * Self.etaFactor + (prefix?.seconds ?? 0),
                         isPartlyUncovered: prefix != nil, walkMetres: walkMetres,
                         destinationZone: destinationZone, startZone: startZone, destination: request.destination)
    }

    private func appleOnly(_ request: RouteRequest) async throws -> RoutePlan {
        let leg = try await approach.leg(from: request.start, to: request.destination)
        var cumulative: [Double] = []
        var run = 0.0
        for (i, p) in leg.points.enumerated() {
            if i > 0 { run += leg.points[i - 1].metres(to: p) }
            cumulative.append(run)
        }
        let steps = leg.steps.map { RouteStep(maneuver: .straight, street: nil, startMetre: $0.startMetre, instruction: $0.instruction) }
            + [RouteStep(maneuver: .arrive, street: nil, startMetre: run, instruction: nil)]
        return RoutePlan(points: leg.points, cumulative: cumulative, steps: steps,
                         limits: [Int](repeating: 0, count: leg.points.count), seconds: leg.seconds,
                         isPartlyUncovered: true, walkMetres: nil, destinationZone: nil, startZone: nil,
                         destination: request.destination)
    }
}
