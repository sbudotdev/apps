import Foundation

/// The keys pressed today. Only a count: what you type is never read or kept.
nonisolated struct KeystrokeTally: Equatable, Sendable {
    /// The start of the day the count belongs to.
    private(set) var day: Date
    private(set) var count: Int

    init(day: Date = .distantPast, count: Int = 0) {
        self.day = day
        self.count = count
    }

    /// Adds one key press; the first press of a new day starts again from one.
    mutating func record(at date: Date, calendar: Calendar = .current) {
        let today = calendar.startOfDay(for: date)
        if today != day {
            day = today
            count = 0
        }
        count += 1
    }

    /// The count for the day of `date`: zero once that day is over.
    func count(on date: Date, calendar: Calendar = .current) -> Int {
        calendar.isDate(day, inSameDayAs: date) ? count : 0
    }
}
