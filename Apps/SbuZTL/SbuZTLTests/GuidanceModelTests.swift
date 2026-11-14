import Foundation
import Testing
@testable import SbuZTL

struct GuidanceModelTests {
    @Test("Each turn is announced far ahead and again at the corner",
          arguments: [(400.0, nil), (300.0, 300.0), (120.0, 300.0), (60.0, 60.0), (20.0, 60.0)] as [(Double, Double?)])
    func threshold(metres: Double, expected: Double?) {
        #expect(GuidanceModel.threshold(metresToManeuver: metres) == expected)
    }

    @Test("A failed reroute waits before the next attempt")
    func rerouteInterval() {
        let first = Date(timeIntervalSince1970: 1_000)
        #expect(GuidanceModel.mayReroute(after: nil, at: first))
        #expect(!GuidanceModel.mayReroute(after: first, at: first.addingTimeInterval(3)))
        #expect(GuidanceModel.mayReroute(after: first, at: first.addingTimeInterval(GuidanceModel.rerouteInterval)))
    }
}
