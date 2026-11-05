import Foundation
import Testing
@testable import SbuSocial

struct TallyTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Rome") ?? .gmt
        return calendar
    }()

    /// Thursday 5 November 2026, 10:00 in Rome.
    private var morning: Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: 5, hour: 10)) ?? .distantPast
    }

    @Test func nothingBlockedUntilABlockRuns() {
        #expect(Tally().blocked(now: morning, calendar: calendar) == 0)
    }

    @Test func blockedTimeRunsWhileABlockDoesAndStopsWithIt() {
        var tally = Tally()
        tally.settle(isBlocking: true, now: morning, calendar: calendar)
        #expect(tally.blocked(now: morning.addingTimeInterval(600), calendar: calendar) == 600)

        tally.settle(isBlocking: false, now: morning.addingTimeInterval(900), calendar: calendar)
        #expect(tally.blocked(now: morning.addingTimeInterval(5000), calendar: calendar) == 900)
    }

    @Test func settlingAgainDuringABlockChangesNothing() {
        var tally = Tally()
        tally.settle(isBlocking: true, now: morning, calendar: calendar)
        tally.settle(isBlocking: true, now: morning.addingTimeInterval(300), calendar: calendar)
        #expect(tally.blocked(now: morning.addingTimeInterval(600), calendar: calendar) == 600)
    }

    @Test func twoBlocksInADayAddUp() {
        var tally = Tally()
        tally.settle(isBlocking: true, now: morning, calendar: calendar)
        tally.settle(isBlocking: false, now: morning.addingTimeInterval(900), calendar: calendar)
        tally.settle(isBlocking: true, now: morning.addingTimeInterval(3600), calendar: calendar)
        tally.settle(isBlocking: false, now: morning.addingTimeInterval(4200), calendar: calendar)
        #expect(tally.blocked(now: morning.addingTimeInterval(9000), calendar: calendar) == 1500)
    }

    @Test func theRecordIsTheBestDay() {
        var tally = Tally()
        tally.settle(isBlocking: true, now: morning, calendar: calendar)
        tally.settle(isBlocking: false, now: morning.addingTimeInterval(900), calendar: calendar)

        let nextMorning = morning.addingTimeInterval(86_400)
        tally.settle(isBlocking: true, now: nextMorning, calendar: calendar)
        tally.settle(isBlocking: false, now: nextMorning.addingTimeInterval(300), calendar: calendar)

        #expect(tally.blocked(now: nextMorning.addingTimeInterval(600), calendar: calendar) == 300)
        #expect(tally.record == 900)
    }

    @Test func aBlockAcrossMidnightCountsOnBothDays() throws {
        var tally = Tally()
        let lateEvening = try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 5, hour: 23, minute: 30)))
        let afterMidnight = lateEvening.addingTimeInterval(3600)
        tally.settle(isBlocking: true, now: lateEvening, calendar: calendar)
        tally.settle(isBlocking: true, now: afterMidnight, calendar: calendar)

        // Thursday keeps its half hour, Friday has the half hour since midnight.
        #expect(tally.record == 1800)
        #expect(tally.blocked(now: afterMidnight, calendar: calendar) == 1800)
    }

    @Test func aRunningBlockReadAfterMidnightCountsOnlyToday() throws {
        var tally = Tally()
        let lateEvening = try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 5, hour: 23, minute: 30)))
        tally.settle(isBlocking: true, now: lateEvening, calendar: calendar)
        #expect(tally.blocked(now: lateEvening.addingTimeInterval(3600), calendar: calendar) == 1800)
    }

    @Test func survivesARelaunch() {
        let defaults = UserDefaults(suiteName: "TallyTests-\(UUID())")!
        let saved = Tally.update(in: defaults) { $0.settle(isBlocking: true, now: morning, calendar: calendar) }
        #expect(Tally.load(from: defaults) == saved)
        #expect(saved.blockingSince == morning)
    }
}
