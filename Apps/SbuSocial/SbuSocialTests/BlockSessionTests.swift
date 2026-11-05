import Foundation
import Testing
@testable import SbuSocial

struct BlockSessionTests {
    private static let rome: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Rome") ?? .gmt
        return calendar
    }()

    /// A moment in November 2026: the 5th is a Thursday, the 7th a Saturday, the 9th a Monday.
    private static func date(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        rome.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute)) ?? .distantPast
    }

    nonisolated struct Moment: Sendable, CustomTestStringConvertible {
        let day: Int
        let hour: Int
        var minute = 0
        let runs: Bool
        let testDescription: String
    }

    nonisolated static let workdayMoments = [
        Moment(day: 5, hour: 9, minute: 29, runs: false, testDescription: "a minute before it starts"),
        Moment(day: 5, hour: 9, minute: 30, runs: true, testDescription: "at its start"),
        Moment(day: 5, hour: 16, minute: 59, runs: true, testDescription: "its last minute"),
        Moment(day: 5, hour: 17, runs: false, testDescription: "at its end"),
        Moment(day: 7, hour: 10, runs: false, testDescription: "a Saturday morning"),
    ]

    @Test(arguments: workdayMoments)
    func aWorkdaySessionRunsInsideItsHoursOnItsDays(_ moment: Moment) {
        let work = BlockSession(name: "Lavoro", start: 9 * 60 + 30, end: 17 * 60, days: [2, 3, 4, 5, 6])
        #expect(work.isRunning(at: Self.date(moment.day, moment.hour, moment.minute), calendar: Self.rome) == moment.runs)
    }

    nonisolated static let nightMoments = [
        Moment(day: 5, hour: 21, minute: 59, runs: false, testDescription: "Thursday before ten"),
        Moment(day: 5, hour: 22, runs: true, testDescription: "Thursday at ten"),
        Moment(day: 6, hour: 2, runs: true, testDescription: "Friday at two: still Thursday's night"),
        Moment(day: 6, hour: 5, runs: false, testDescription: "Friday at five"),
        Moment(day: 7, hour: 2, runs: true, testDescription: "Saturday at two: Friday's night"),
        Moment(day: 7, hour: 23, runs: false, testDescription: "Saturday night is not chosen"),
        Moment(day: 8, hour: 2, runs: false, testDescription: "Sunday at two: Saturday's night"),
        Moment(day: 9, hour: 2, runs: false, testDescription: "Monday at two: Sunday's night"),
    ]

    @Test(arguments: nightMoments)
    func aNightBelongsToTheDayItStartsOn(_ moment: Moment) {
        let night = BlockSession(name: "Notte", start: 22 * 60, end: 5 * 60, days: [2, 3, 4, 5, 6])
        #expect(night.isRunning(at: Self.date(moment.day, moment.hour, moment.minute), calendar: Self.rome) == moment.runs)
    }

    @Test func aSessionTurnedOffNeverRuns() {
        var work = BlockSession(name: "Lavoro", start: 9 * 60, end: 17 * 60)
        work.isOn = false
        #expect(!work.isRunning(at: Self.date(5, 12), calendar: Self.rome))
    }

    /// 22:00–5:00, 9:00–9:15, 9:00–9:10 and a start equal to the end.
    @Test(arguments: [(1320, 300, 420), (540, 555, 15), (540, 550, 10), (600, 600, 0)] as [(Int, Int, Int)])
    func lengthCrossesMidnight(start: Int, end: Int, minutes: Int) {
        let session = BlockSession(name: "Prova", start: start, end: end)
        #expect(session.minutes == minutes)
        // Screen Time schedules last at least 15 minutes.
        #expect(session.isValid == (minutes >= 15))
    }

    @Test func theScheduleRepeatsEveryDayAtItsHours() {
        let schedule = BlockSession(name: "Cena", start: 18 * 60 + 30, end: 19 * 60 + 30).schedule
        #expect(schedule.intervalStart.hour == 18 && schedule.intervalStart.minute == 30)
        #expect(schedule.intervalEnd.hour == 19 && schedule.intervalEnd.minute == 30)
        #expect(schedule.repeats)
    }

    @Test func everyPresetCanBeScheduled() {
        let presets = BlockSession.presets
        #expect(presets.count == 7)
        #expect(presets.filter { !$0.isValid }.isEmpty)
        #expect(Set(presets.map(\.id)).count == 7)
    }
}
