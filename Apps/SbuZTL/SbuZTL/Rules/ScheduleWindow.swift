/// One line of a timetable, in the Rome clock.
nonisolated struct ScheduleWindow: Sendable {
    /// `Calendar` weekdays, Sunday is 1, of the day the window opens.
    let days: Set<Int>
    let start: Int
    /// In minutes from midnight; at or before `start` the window ends the next day.
    let end: Int
    /// Months in which it opens, `nil` for all.
    var months: Set<Int>?

    static let mondayToFriday: Set<Int> = [2, 3, 4, 5, 6]
    static let mondayToSaturday: Set<Int> = [2, 3, 4, 5, 6, 7]
    static let everyDay: Set<Int> = [1, 2, 3, 4, 5, 6, 7]

    func opens(weekday: Int, month: Int) -> Bool {
        days.contains(weekday) && (months?.contains(month) ?? true)
    }

    func coversOpeningDay(minute: Int) -> Bool {
        minute >= start && minute < (end > start ? end : 1440)
    }

    func coversNextDay(minute: Int) -> Bool {
        end <= start && minute < end
    }
}
