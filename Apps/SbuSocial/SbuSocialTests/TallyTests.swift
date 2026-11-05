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

    // MARK: Serie

    private let start = Day(ordinal: 20_762)

    private func day(_ offset: Int) -> Day {
        Day(ordinal: start.ordinal + offset)
    }

    @Test func noStreakBeforeYouBegin() {
        #expect(Tally().streak(on: start) == 0)
    }

    @Test func theFirstDayCountsWhileItHolds() {
        var tally = Tally()
        tally.begin(on: start)
        #expect(tally.streak(on: start) == 1)
        #expect(tally.streak(on: day(4)) == 5)
    }

    @Test func beginningAgainKeepsTheFirstDay() {
        var tally = Tally()
        tally.begin(on: start)
        tally.begin(on: day(3))
        #expect(tally.streak(on: day(3)) == 4)
    }

    @Test func aBrokenDayIsZeroAndTheNextStartsOver() {
        var tally = Tally()
        tally.begin(on: start)
        tally.markExceeded(on: day(2))
        #expect(tally.streak(on: day(2)) == 0)
        #expect(tally.streak(on: day(3)) == 1)
        #expect(tally.streak(on: day(5)) == 3)
    }

    @Test func goingOverTheGoalBreaksTheDayToo() {
        var tally = Tally()
        tally.begin(on: start)
        tally.markOverGoal(on: day(1))
        #expect(tally.streak(on: day(1)) == 0)
        #expect(!tally.isKept(day(1), today: day(2)))
        #expect(tally.isKept(start, today: day(2)))
    }

    @Test func onlyDaysFromTheFirstToTodayCanBeKept() {
        var tally = Tally()
        tally.begin(on: start)
        #expect(!tally.isKept(day(-1), today: day(1)))
        #expect(tally.isKept(day(1), today: day(1)))
        #expect(!tally.isKept(day(2), today: day(1)))
    }

    @Test func restoringTakesBackTheLastBrokenDay() {
        var tally = Tally()
        tally.begin(on: start)
        tally.markExceeded(on: day(1))
        tally.markOverGoal(on: day(2))
        tally.restoreStreak()
        // Day 2 is whole again; day 1 still breaks.
        #expect(tally.streak(on: day(3)) == 2)
    }

    // MARK: Punti

    @Test func everyFinishedDayUnderTheGoalGivesPoints() {
        var tally = Tally()
        tally.begin(on: start)
        #expect(tally.xp(on: start) == 0)
        #expect(tally.xp(on: day(3)) == 3 * Tally.dayXP)

        tally.markOverGoal(on: day(1))
        // Going beyond an Intenzione's openings breaks the Serie, not the day's points.
        tally.markExceeded(on: day(2))
        #expect(tally.xp(on: day(3)) == 2 * Tally.dayXP)
    }

    @Test func aFinishedBlockGivesItsPointsOnceADay() {
        var tally = Tally()
        tally.begin(on: start)
        tally.completeBlock("cena", xp: 10, on: start)
        tally.completeBlock("cena", xp: 10, on: start)
        #expect(tally.xp(on: start) == 10)

        tally.completeBlock("cena", xp: 10, on: day(1))
        #expect(tally.xp(on: day(1)) == 20 + Tally.dayXP)
    }

    // MARK: Missione del giorno

    @Test func theQuestStartsOverEveryDay() {
        var tally = Tally()
        tally.complete(.tip, on: start)
        tally.complete(.review, on: start)
        #expect(tally.quest(on: start) == [.tip, .review])
        #expect(tally.quest(on: day(1)).isEmpty)

        tally.complete(.tip, on: day(1))
        #expect(tally.quest(on: day(1)) == [.tip])
    }

    @Test func finishingABlockIsOneOfTheQuestTasks() {
        var tally = Tally()
        tally.completeBlock("blocknow", xp: 10, on: start)
        #expect(tally.quest(on: start) == [.block])
    }

    @Test func theRecordCanStartOver() {
        var tally = Tally()
        tally.record = 3600
        tally.resetRecord()
        #expect(tally.record == 0)
    }

    @Test func survivesARelaunch() {
        let defaults = UserDefaults(suiteName: "TallyTests-\(UUID())")!
        let saved = Tally.update(in: defaults) { $0.settle(isBlocking: true, now: morning, calendar: calendar) }
        #expect(Tally.load(from: defaults) == saved)
        #expect(saved.blockingSince == morning)
    }
}
