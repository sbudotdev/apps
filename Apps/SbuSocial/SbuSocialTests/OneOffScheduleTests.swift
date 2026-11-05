import DeviceActivity
import Foundation
import Testing
@testable import SbuSocial

struct OneOffScheduleTests {
    private let calendar = Calendar(identifier: .gregorian)

    @Test func runsOnceBetweenTwoMoments() throws {
        let now = Date(timeIntervalSince1970: 1_792_000_000)
        let schedule = DeviceActivitySchedule.oneOff(from: now.addingTimeInterval(600), to: now.addingTimeInterval(1500), calendar: calendar)
        let start = try #require(calendar.date(from: schedule.intervalStart))
        let end = try #require(calendar.date(from: schedule.intervalEnd))
        #expect(start.timeIntervalSince(now) == 600)
        #expect(end.timeIntervalSince(start) == 900)
        #expect(!schedule.repeats)
    }
}
