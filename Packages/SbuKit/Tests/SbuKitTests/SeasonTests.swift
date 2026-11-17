import Foundation
import SwiftUI
import Testing
@testable import SbuKit

/// Seasons come from the date alone (ADR-0019): Christmas from 1 December to 6 January, both included.
struct SeasonTests {
    private static func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12, in calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    private static func gregorian(_ timeZone: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timeZone)!
        return calendar
    }

    private static let rome = gregorian("Europe/Rome")

    @Test(arguments: ["2026-12-01", "2026-12-31", "2027-01-01", "2027-01-06"])
    func christmasIsOn(_ day: String) {
        #expect(SbuSeason.active(on: Self.date(day), in: Self.rome) == .christmas)
    }

    @Test(arguments: ["2026-11-30", "2027-01-07", "2027-07-15"])
    func noSeasonOn(_ day: String) {
        #expect(SbuSeason.active(on: Self.date(day), in: Self.rome) == nil)
    }

    /// Noon in Rome of an ISO day such as `2026-12-01`.
    private static func date(_ isoDay: String) -> Date {
        let parts = isoDay.split(separator: "-").compactMap { Int($0) }
        return date(parts[0], parts[1], parts[2], in: rome)
    }

    @Test func edgesHoldAtMidnight() {
        #expect(SbuSeason.active(on: Self.date(2026, 12, 1, hour: 0, in: Self.rome), in: Self.rome) == .christmas)
        #expect(SbuSeason.active(on: Self.date(2026, 11, 30, hour: 23, in: Self.rome).addingTimeInterval(3599), in: Self.rome) == nil)
        #expect(SbuSeason.active(on: Self.date(2027, 1, 7, hour: 0, in: Self.rome), in: Self.rome) == nil)
    }

    @Test func leapYearChangesNothing() {
        #expect(SbuSeason.active(on: Self.date(2028, 2, 29, in: Self.rome), in: Self.rome) == nil)
        #expect(SbuSeason.active(on: Self.date(2028, 12, 1, in: Self.rome), in: Self.rome) == .christmas)
        #expect(SbuSeason.active(on: Self.date(2029, 1, 6, in: Self.rome), in: Self.rome) == .christmas)
    }

    /// The same instant is 1 December in Rome and still 30 November in New York.
    @Test func followsTheCalendarTimeZone() {
        let instant = Self.date(2026, 12, 1, hour: 1, in: Self.rome)
        #expect(SbuSeason.active(on: instant, in: Self.rome) == .christmas)
        #expect(SbuSeason.active(on: instant, in: Self.gregorian("America/New_York")) == nil)
        #expect(SbuSeason.active(on: instant, in: Self.gregorian("Asia/Tokyo")) == .christmas)
    }

    /// A person on another calendar system still gets Christmas on the Gregorian dates of their time zone.
    @Test func otherCalendarSystemsUseGregorianDates() {
        var hebrew = Calendar(identifier: .hebrew)
        hebrew.timeZone = Self.rome.timeZone
        #expect(SbuSeason.active(on: Self.date(2026, 12, 24, in: Self.rome), in: hebrew) == .christmas)
        #expect(SbuSeason.active(on: Self.date(2026, 11, 20, in: Self.rome), in: hebrew) == nil)
    }

    @Test func environmentCanBeForced() {
        var environment = EnvironmentValues()
        environment.sbuSeason = .christmas
        #expect(environment.sbuSeason == .christmas)
        environment.sbuSeason = nil
        #expect(environment.sbuSeason == nil)
    }
}
