@testable import SbuKeys
import Foundation
import Testing

struct KeystrokeTallyTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Rome")!
        return calendar
    }()

    private func date(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute))!
    }

    @Test func startsAtZero() {
        #expect(KeystrokeTally().count(on: date(24, 9), calendar: calendar) == 0)
    }

    @Test func countsPressesOfTheSameDay() {
        var tally = KeystrokeTally()
        for hour in [0, 9, 23] {
            tally.record(at: date(24, hour), calendar: calendar)
        }
        #expect(tally.count(on: date(24, 23, 59), calendar: calendar) == 3)
    }

    @Test func aNewDayStartsFromOne() {
        var tally = KeystrokeTally()
        tally.record(at: date(24, 23, 59), calendar: calendar)
        tally.record(at: date(24, 23, 59), calendar: calendar)
        tally.record(at: date(25, 0, 1), calendar: calendar)
        #expect(tally.count(on: date(25, 8), calendar: calendar) == 1)
    }

    @Test func yesterdaysCountReadsZeroToday() {
        var tally = KeystrokeTally()
        tally.record(at: date(24, 10), calendar: calendar)
        #expect(tally.count(on: date(25, 10), calendar: calendar) == 0)
    }
}
