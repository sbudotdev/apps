import Testing
@testable import SbuZTL

struct GuidanceTrackerTests {
    /// 400 m due north, with a turn at 200 m.
    static let plan: RoutePlan = {
        let points = (0..<5).map { Point(Double($0) * 0.0009, 0) }
        let cumulative = points.map { $0.metres(to: points[0]) }
        return RoutePlan(points: points, cumulative: cumulative,
                         steps: [RouteStep(maneuver: .depart, street: "A", startMetre: 0, instruction: nil),
                                 RouteStep(maneuver: .right, street: "B", startMetre: cumulative[2], instruction: nil),
                                 RouteStep(maneuver: .arrive, street: nil, startMetre: cumulative[4], instruction: nil)],
                         limits: [30, 30, 50, 50, 0], seconds: 40, isPartlyUncovered: false, walkMetres: nil,
                         destinationZone: nil, startZone: nil, destination: points[4])
    }()

    @Test("Progress along the route")
    func progress() {
        var tracker = GuidanceTracker(plan: Self.plan)
        let state = tracker.update(at: Point(0.00045, 0), accuracy: 5)
        #expect(state.stepIndex == 1)
        #expect(abs(state.metresToManeuver - 150) < 2)
        #expect(abs(state.remainingMetres - 350) < 2)
        #expect(state.limit == 30)
        #expect(!state.isOffRoute)
    }

    @Test("Three good fixes away make it off route; one doesn't")
    func offRoute() {
        var tracker = GuidanceTracker(plan: Self.plan)
        let away = Point(0.0009, 0.002)
        #expect(!tracker.update(at: away, accuracy: 5).isOffRoute)
        #expect(!tracker.update(at: away, accuracy: 5).isOffRoute)
        #expect(tracker.update(at: away, accuracy: 5).isOffRoute)
    }

    @Test("Weak fixes never declare off route")
    func weakGPS() {
        var tracker = GuidanceTracker(plan: Self.plan)
        let away = Point(0.0009, 0.002)
        for _ in 0..<5 {
            #expect(!tracker.update(at: away, accuracy: 200).isOffRoute)
        }
    }

    @Test("Arrival within 30 m of the end")
    func arrival() {
        var tracker = GuidanceTracker(plan: Self.plan)
        #expect(!tracker.update(at: Point(0.0030, 0), accuracy: 5).hasArrived)
        #expect(tracker.update(at: Point(0.00358, 0), accuracy: 5).hasArrived)
    }
}
