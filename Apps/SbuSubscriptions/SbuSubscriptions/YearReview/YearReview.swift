import Foundation

/// "Il tuo 2026 in abbonamenti": what you paid in a calendar year, in each subscription's own currency, and what
/// renews the January after. Shown from 1 December to 15 January, from the date alone, as the seasons (ADR-0023).
nonisolated struct YearReview: Identifiable {
    /// One subscription, as the review reads it.
    struct Entry {
        var name: String
        var currencyCode: String
        var schedule: BillingSchedule
        /// The day it was last paused or cancelled, if it is now; no payment after it counts.
        var stoppedOn: Date?
        var isActive: Bool
        /// What one payment costs on a day, after any price change.
        var price: (Date) -> Decimal
    }

    struct Amount: Hashable, Sendable {
        var currencyCode: String
        var value: Decimal
    }

    struct Renewal: Hashable, Sendable {
        var name: String
        var date: Date
        var amount: Amount
    }

    let year: Int
    var id: Int { year }
    /// What you paid in the year up to today, one total per currency, never added up across currencies:
    /// your main currency first, then the others largest first.
    let spent: [Amount]
    /// The first January payment of each active subscription, by date.
    let januaryRenewals: [Renewal]
    /// No subscription at all.
    let isEmpty: Bool

    init(year: Int, entries: [Entry], through today: Date, mainCurrency: String, calendar: Calendar) {
        self.year = year
        isEmpty = entries.isEmpty
        let gregorian = Self.gregorian(calendar)
        let start = gregorian.date(from: DateComponents(year: year, month: 1, day: 1)) ?? .distantPast
        let nextYear = gregorian.date(from: DateComponents(year: year + 1, month: 1, day: 1)) ?? .distantFuture
        // Payments still to come in December aren't spent yet.
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: today)) ?? today
        let february = gregorian.date(from: DateComponents(year: year + 1, month: 2, day: 1)) ?? .distantFuture

        var totals: [String: Decimal] = [:]
        var renewals: [Renewal] = []
        for entry in entries {
            let end = entry.stoppedOn.flatMap { calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: $0)) }
            for payment in entry.schedule.payments(from: start, to: min(end ?? nextYear, nextYear, tomorrow), in: calendar) {
                totals[entry.currencyCode, default: 0] += entry.price(payment)
            }
            if entry.isActive, let first = entry.schedule.payments(from: nextYear, to: february, in: calendar).first {
                renewals.append(Renewal(name: entry.name, date: first,
                                        amount: Amount(currencyCode: entry.currencyCode, value: entry.price(first))))
            }
        }
        spent = totals.map { Amount(currencyCode: $0.key, value: $0.value) }
            .sorted { ($0.currencyCode == mainCurrency ? 1 : 0, $0.value, $1.currencyCode) > ($1.currencyCode == mainCurrency ? 1 : 0, $1.value, $0.currencyCode) }
        januaryRenewals = renewals.sorted { ($0.date, $0.name) < ($1.date, $1.name) }
    }

    /// The year to look back at on `date`: this year in December, last year until 15 January, otherwise `nil`;
    /// also `nil` once you closed that year's review.
    static func year(on date: Date, closed closedYear: Int = 0, in calendar: Calendar = .current) -> Int? {
        let day = gregorian(calendar).dateComponents([.year, .month, .day], from: date)
        guard let year = day.year else { return nil }
        let reviewed: Int? = switch (day.month, day.day) {
        case (12, _): year
        case (1, let dayOfMonth?) where dayOfMonth <= 15: year - 1
        default: nil
        }
        return reviewed == closedYear ? nil : reviewed
    }

    /// Years are always Gregorian, in the time zone of `calendar`: "Il tuo 2026" on every calendar system.
    private static func gregorian(_ calendar: Calendar) -> Calendar {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = calendar.timeZone
        return gregorian
    }
}
