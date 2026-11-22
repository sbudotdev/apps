import Foundation

/// A day of the year, such as 12 March, whatever the year: the days of Accadde oggi.
nonisolated struct DayOfYear: Hashable, Sendable {
    var month: Int
    var day: Int

    init(month: Int, day: Int) {
        self.month = month
        self.day = day
    }

    init(_ date: Date, calendar: Calendar = .current) {
        let components = calendar.dateComponents([.month, .day], from: date)
        self.init(month: components.month ?? 1, day: components.day ?? 1)
    }

    /// The day in `year`, for formatting; `nil` for 29 February in a common year.
    func date(in year: Int, calendar: Calendar = .current) -> Date? {
        let date = calendar.date(from: DateComponents(year: year, month: month, day: day))
        return date.flatMap { calendar.component(.day, from: $0) == day ? $0 : nil }
    }
}
