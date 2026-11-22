import Foundation
import Testing
@testable import SbuClean

/// The calendar of Accadde oggi: past years only, decided items left out.
struct OnThisDayTests {
    private let items = [
        Fixture.photo("2025-03-12", on: Fixture.date(3, 12, year: 2025)),
        Fixture.photo("2024-03-12", on: Fixture.date(3, 12, year: 2024)),
        Fixture.photo("2026-03-12", on: Fixture.date(3, 12)),
        Fixture.photo("2024-03-20", on: Fixture.date(3, 20, year: 2024)),
        Fixture.photo("2024-04-12", on: Fixture.date(4, 12, year: 2024)),
    ]

    private func builder(kept: [String] = []) -> QueueBuilder {
        var state = CleanState()
        for id in kept {
            state.set(.keep, for: id)
        }
        return QueueBuilder(items: items, state: state, now: Fixture.date(10, 23))
    }

    @Test func aDayGathersPastYearsOnly() {
        let queue = builder().queue(for: .onDay(DayOfYear(month: 3, day: 12)))

        #expect(queue == ["2025-03-12", "2024-03-12"])
    }

    @Test func theMonthCountsWhatIsLeftToSee() {
        let counts = builder(kept: ["2024-03-12"]).dayCounts(inMonth: 3)

        #expect(counts == [12: 1, 20: 1])
    }

    @Test func theTwentyNinthOfFebruaryHasNoDateInACommonYear() {
        let leapDay = DayOfYear(month: 2, day: 29)

        #expect(leapDay.date(in: 2025) == nil)
        #expect(leapDay.date(in: 2024) != nil)
    }
}
