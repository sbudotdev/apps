import Foundation
import Testing
@testable import SbuSubscriptions

struct YearReviewTests {
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Rome")!
        return calendar
    }()

    func day(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    func entry(_ name: String = "Musica", price: Decimal = 10, currency: String = "EUR", start: Date, cycle: BillingCycle = .monthly,
               count: Int? = nil, stoppedOn: Date? = nil, isActive: Bool = true,
               priceOn: ((Date) -> Decimal)? = nil) -> YearReview.Entry {
        YearReview.Entry(name: name, currencyCode: currency, schedule: BillingSchedule(start: start, cycle: cycle, paymentCount: count),
                         stoppedOn: stoppedOn, isActive: isActive, price: priceOn ?? { _ in price })
    }

    func makeReview(entries: [YearReview.Entry], calendar: Calendar, today: Date? = nil, mainCurrency: String = "EUR") -> YearReview {
        YearReview(year: 2026, entries: entries, through: today ?? day(2027, 1, 10), mainCurrency: mainCurrency, calendar: calendar)
    }

    // MARK: When it shows

    @Test(arguments: [
        (11, 30, nil), (12, 1, 2026), (12, 31, 2026),
    ] as [(Int, Int, Int?)])
    func showsFromTheFirstOfDecember(month: Int, dayOfMonth: Int, year: Int?) {
        #expect(YearReview.year(on: day(2026, month, dayOfMonth, hour: 12), in: calendar) == year)
    }

    @Test func inJanuaryItLooksBackAtTheYearJustEnded() {
        #expect(YearReview.year(on: day(2027, 1, 1), in: calendar) == 2026)
        #expect(YearReview.year(on: day(2027, 1, 15, hour: 23), in: calendar) == 2026)
        #expect(YearReview.year(on: day(2027, 1, 16), in: calendar) == nil)
    }

    @Test func aMidSummerDayHasNoReview() {
        #expect(YearReview.year(on: day(2026, 7, 15), in: calendar) == nil)
    }

    @Test func closedForTheYearItStaysHiddenUntilNextDecember() {
        #expect(YearReview.year(on: day(2026, 12, 10), closed: 2026, in: calendar) == nil)
        #expect(YearReview.year(on: day(2027, 1, 10), closed: 2026, in: calendar) == nil)
        #expect(YearReview.year(on: day(2027, 12, 1), closed: 2026, in: calendar) == 2027)
    }

    // MARK: What you spent

    @Test func aMonthlyPlanPaysTwelveTimesInTheYear() {
        let review = makeReview(entries: [entry(start: day(2025, 3, 10))], calendar: calendar)
        #expect(review.spent == [YearReview.Amount(currencyCode: "EUR", value: 120)])
    }

    @Test func aYearlyPlanPaysOnceInTheYear() {
        let review = makeReview(entries: [entry(price: 80, start: day(2024, 9, 1), cycle: .yearly)], calendar: calendar)
        #expect(review.spent == [YearReview.Amount(currencyCode: "EUR", value: 80)])
    }

    @Test func aWeeklyPlanPaysEveryWeekOfTheYear() {
        // Thursday 1 January 2026: 53 Thursdays in 2026.
        let review = makeReview(entries: [entry(price: 2, start: day(2026, 1, 1), cycle: .weekly)], calendar: calendar)
        #expect(review.spent == [YearReview.Amount(currencyCode: "EUR", value: 106)])
    }

    @Test func aPlanStartedMidYearCountsOnlyFromItsStart() {
        let review = makeReview(entries: [entry(start: day(2026, 7, 20))], calendar: calendar)
        #expect(review.spent == [YearReview.Amount(currencyCode: "EUR", value: 60)], "July to December")
    }

    @Test func aStoppedPlanCountsUpToTheDayItStopped() {
        let review = makeReview(entries: [entry(start: day(2025, 1, 5), stoppedOn: day(2026, 4, 10), isActive: false)],
                                calendar: calendar)
        #expect(review.spent == [YearReview.Amount(currencyCode: "EUR", value: 40)], "January to April")
    }

    @Test func eachPaymentAtItsPriceThatDay() {
        let rise = day(2026, 7, 1)
        let review = makeReview(entries: [entry(start: day(2025, 1, 1)) { $0 < rise ? 10 : 12 }], calendar: calendar)
        #expect(review.spent == [YearReview.Amount(currencyCode: "EUR", value: 132)])
    }

    @Test func eachCurrencyKeepsItsOwnTotalLargestFirst() {
        let review = makeReview(entries: [
            entry("Film", price: 10, start: day(2025, 1, 1)),
            entry("Design", price: 12, currency: "USD", start: day(2025, 1, 1)),
            entry("Giornale", price: 50, start: day(2025, 6, 1), cycle: .yearly),
        ], calendar: calendar)
        #expect(review.spent == [
            YearReview.Amount(currencyCode: "EUR", value: 170),
            YearReview.Amount(currencyCode: "USD", value: 144),
        ])
    }

    @Test func inDecemberOnlyWhatYouAlreadyPaidCounts() {
        let review = makeReview(entries: [entry(start: day(2025, 1, 20))], calendar: calendar, today: day(2026, 12, 10, hour: 9))
        #expect(review.spent == [YearReview.Amount(currencyCode: "EUR", value: 110)], "January to November: 20 December is still to come")
        #expect(review.januaryRenewals.map(\.date) == [day(2027, 1, 20)])
    }

    @Test func aPaymentDueTodayCounts() {
        let review = makeReview(entries: [entry(start: day(2025, 1, 10))], calendar: calendar, today: day(2026, 12, 10, hour: 9))
        #expect(review.spent == [YearReview.Amount(currencyCode: "EUR", value: 120)])
    }

    @Test func yourMainCurrencyComesFirstEvenWhenSmaller() {
        let review = makeReview(entries: [
            entry("Film", price: 25, start: day(2025, 1, 1)),
            entry("Anime", price: 1000, currency: "JPY", start: day(2025, 1, 1)),
        ], calendar: calendar)
        #expect(review.spent.map(\.currencyCode) == ["EUR", "JPY"])
    }

    @Test func noSubscriptionsIsAnEmptyReview() {
        let review = makeReview(entries: [], calendar: calendar)
        #expect(review.isEmpty)
        #expect(review.spent.isEmpty)
        #expect(review.januaryRenewals.isEmpty)
    }

    @Test func aPlanThatPaidNothingInTheYearLeavesNoTotal() {
        let review = makeReview(entries: [entry(start: day(2027, 3, 1))], calendar: calendar)
        #expect(review.spent.isEmpty)
        #expect(!review.isEmpty, "You still have a subscription")
    }

    // MARK: What renews in January

    @Test func listsTheFirstJanuaryPaymentOfEachActivePlanByDate() {
        let review = makeReview(entries: [
            entry("Musica", start: day(2025, 3, 20)),
            entry("Giornale", price: 80, start: day(2024, 1, 8), cycle: .yearly),
            entry("Corsa", price: 2, start: day(2026, 1, 1), cycle: .weekly),
            entry("Palestra", start: day(2025, 1, 2), stoppedOn: day(2026, 5, 1), isActive: false),
            entry("Cloud", start: day(2026, 1, 1), cycle: .yearly, count: 1),
        ], calendar: calendar)
        #expect(review.januaryRenewals.map(\.name) == ["Corsa", "Giornale", "Musica"])
        #expect(review.januaryRenewals.map(\.date) == [day(2027, 1, 7), day(2027, 1, 8), day(2027, 1, 20)])
        #expect(review.januaryRenewals[1].amount == YearReview.Amount(currencyCode: "EUR", value: 80))
    }
}
