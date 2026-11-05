import Foundation

/// A calendar day as a count of days since 1 January 1970, so days subtract and compare:
/// yesterday is `ordinal - 1`.
nonisolated struct Day: Codable, Hashable, Sendable {
    var ordinal: Int

    init(ordinal: Int) {
        self.ordinal = ordinal
    }

    /// The day `date` falls on in `calendar`'s time zone.
    init(_ date: Date, calendar: Calendar = .current) {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = calendar.timeZone
        let parts = gregorian.dateComponents([.year, .month, .day], from: date)

        // UTC has no daylight saving time, so its midnights are exactly 86 400 s apart.
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = .gmt
        let midnight = utc.date(from: parts) ?? date
        ordinal = Int((midnight.timeIntervalSince1970 / 86_400).rounded(.down))
    }

    /// Gregorian weekday, 1 for Sunday through 7 for Saturday; day 0 was a Thursday.
    var weekday: Int {
        ((ordinal + 4) % 7 + 7) % 7 + 1
    }
}
