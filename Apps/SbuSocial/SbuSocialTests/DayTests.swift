import Foundation
import Testing
@testable import SbuSocial

struct DayTests {
    private let rome: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Rome") ?? .gmt
        return calendar
    }()

    private func date(_ day: Int, _ hour: Int, _ minute: Int = 0, month: Int = 11) throws -> Date {
        try #require(rome.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute)))
    }

    @Test func theDayChangesAtLocalMidnight() throws {
        let lateEvening = Day(try date(5, 23, 59), calendar: rome)
        let justAfterMidnight = Day(try date(6, 0, 0), calendar: rome)
        #expect(justAfterMidnight.ordinal == lateEvening.ordinal + 1)
    }

    @Test func theSameDayFromMorningToNight() throws {
        #expect(Day(try date(5, 0, 30), calendar: rome) == Day(try date(5, 23, 30), calendar: rome))
    }

    @Test func theTwentyFiveHourDayOfTheClockChangeCountsOnce() throws {
        // On 25 October 2026 Rome goes back one hour.
        let saturday = Day(try date(24, 23, month: 10), calendar: rome)
        let monday = Day(try date(26, 0, 30, month: 10), calendar: rome)
        #expect(monday.ordinal - saturday.ordinal == 2)
    }

    @Test(arguments: [(5, 5), (7, 7), (8, 1), (9, 2)])
    func weekdayRunsFromSundayAsOne(day: Int, weekday: Int) throws {
        #expect(Day(try date(day, 12), calendar: rome).weekday == weekday)
    }
}
