import Foundation
import Testing
@testable import SbuSocial

struct IntentionTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Rome") ?? .gmt
        return calendar
    }()

    /// Thursday 5 November 2026, 10:00 in Rome.
    private var thursday: Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: 5, hour: 10)) ?? .distantPast
    }

    private func today(_ date: Date) -> Day {
        Day(date, calendar: calendar)
    }

    @Test func noOpensUntilYouOpen() {
        #expect(Intention().opens(on: today(thursday)) == 0)
    }

    @Test func anOpenCountsOnce() {
        var intention = Intention()
        intention.open(now: thursday, calendar: calendar)
        #expect(intention.opens(on: today(thursday)) == 1)
    }

    @Test func anOpenLiftsTheShieldForItsMinutesOnly() {
        var intention = Intention(minutes: 10)
        #expect(intention.isLocked(now: thursday, calendar: calendar))
        intention.open(now: thursday, calendar: calendar)
        #expect(!intention.isLocked(now: thursday.addingTimeInterval(599), calendar: calendar))
        #expect(intention.isLocked(now: thursday.addingTimeInterval(600), calendar: calendar))
    }

    @Test func theCountStartsAgainTheNextDay() {
        var intention = Intention()
        intention.open(now: thursday, calendar: calendar)
        intention.open(now: thursday.addingTimeInterval(3600), calendar: calendar)
        let friday = thursday.addingTimeInterval(86_400)
        #expect(intention.opens(on: today(friday)) == 0)
        intention.open(now: friday, calendar: calendar)
        #expect(intention.opens(on: today(friday)) == 1)
    }

    @Test func openingBeyondTheLimitStillOpensAndSaysSo() {
        var intention = Intention(maxOpens: 2)
        let first = intention.open(now: thursday, calendar: calendar)
        let second = intention.open(now: thursday.addingTimeInterval(60), calendar: calendar)
        let third = intention.open(now: thursday.addingTimeInterval(120), calendar: calendar)
        #expect([first, second, third] == [false, false, true])
        #expect(intention.opens(on: today(thursday)) == 3)
    }

    @Test func lockedOnlyOnItsDays() {
        let weekdaysOnly = Intention(days: [2, 3, 4, 5, 6])
        let saturday = thursday.addingTimeInterval(2 * 86_400)
        #expect(weekdaysOnly.isLocked(now: thursday, calendar: calendar))
        #expect(!weekdaysOnly.isLocked(now: saturday, calendar: calendar))
    }

    @Test func surviveARelaunch() throws {
        var intention = Intention(maxOpens: 5, minutes: 3, days: [1, 7])
        intention.open(now: thursday, calendar: calendar)
        let decoded = try JSONDecoder().decode(Intention.self, from: JSONEncoder().encode(intention))
        #expect(decoded == intention)
    }
}
