import Foundation

/// Follows a route from GPS fixes. Pure: fixes in, state out.
nonisolated struct GuidanceTracker: Sendable {
    /// Beyond this a fix is off the road, and three in a row are off the route.
    private static let offRouteMetres = 50.0
    private static let offRouteFixes = 3
    private static let arrivalMetres = 30.0
    /// Fixes worse than this can't say we left the route.
    static let weakAccuracy = 65.0

    let plan: RoutePlan
    private var progressIndex = 0
    private var misses = 0

    init(plan: RoutePlan) {
        self.plan = plan
    }

    mutating func update(at p: Point, accuracy: Double) -> GuidanceState {
        let (index, along, distance) = project(p)
        progressIndex = index
        if accuracy <= Self.weakAccuracy {
            misses = distance > Self.offRouteMetres ? misses + 1 : 0
        }
        var state = GuidanceState()
        state.isOffRoute = misses >= Self.offRouteFixes
        state.remainingMetres = max(0, plan.metres - along)
        state.remainingSeconds = plan.metres > 0 ? plan.seconds * state.remainingMetres / plan.metres : 0
        state.limit = plan.limits.indices.contains(index) ? plan.limits[index] : 0
        let next = plan.steps.firstIndex { $0.startMetre > along + 1 } ?? max(plan.steps.count - 1, 0)
        state.stepIndex = next
        state.metresToManeuver = plan.steps.isEmpty ? 0 : max(0, plan.steps[next].startMetre - along)
        state.hasArrived = state.remainingMetres < Self.arrivalMetres
        return state
    }

    /// The closest segment within a window ahead, so a road that doubles back doesn't jump the progress.
    private func project(_ p: Point) -> (index: Int, along: Double, distance: Double) {
        guard plan.points.count > 1 else { return (0, 0, plan.points.first?.metres(to: p) ?? 0) }
        var best = (index: progressIndex, along: plan.cumulative[progressIndex], distance: Double.infinity)
        let last = min(progressIndex + 200, plan.points.count - 2)
        for i in stride(from: max(progressIndex - 2, 0), through: last, by: 1) {
            let a = plan.points[i], b = plan.points[i + 1]
            let length = a.metres(to: b)
            guard length > 0 else { continue }
            let scale = cos(a.lat * .pi / 180)
            let dx = (b.lon - a.lon) * scale, dy = b.lat - a.lat
            let px = (p.lon - a.lon) * scale, py = p.lat - a.lat
            let t = min(1, max(0, (px * dx + py * dy) / (dx * dx + dy * dy)))
            let foot = Point(a.lat + (b.lat - a.lat) * t, a.lon + (b.lon - a.lon) * t)
            let distance = foot.metres(to: p)
            if distance < best.distance {
                best = (i, plan.cumulative[i] + length * t, distance)
            }
        }
        return best
    }
}
