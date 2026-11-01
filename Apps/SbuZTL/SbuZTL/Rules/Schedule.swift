import Foundation

/// When a zone is in force. Anything the source leaves open is `.unverified`, never `.off`.
nonisolated struct Schedule: Sendable {
    enum HolidayRule: Sendable {
        case included
        case excluded
        /// "Esclusi i festivi infrasettimanali": a holiday on a Saturday stays open to doubt.
        case excludedMidweek
    }

    enum State: Int, Comparable, Sendable {
        case off, on, unverified

        static func < (a: State, b: State) -> Bool { a.rawValue < b.rawValue }
    }

    let windows: [ScheduleWindow]
    var holidays = HolidayRule.excluded
    /// Months the source says the zone is not active ("non attiva").
    var closedMonths: Set<Int> = []
    /// Months the source doesn't mention ("non indicato").
    var silentMonths: Set<Int> = []

    func state(at date: Date, city: City) -> State {
        let calendar = Holidays.calendar
        let c = calendar.dateComponents([.month, .weekday, .hour, .minute], from: date)
        let minute = (c.hour ?? 0) * 60 + (c.minute ?? 0)
        let previous = calendar.date(byAdding: .day, value: -1, to: date) ?? date
        let p = calendar.dateComponents([.month, .weekday], from: previous)
        var result = State.off
        for window in windows {
            if window.opens(weekday: c.weekday ?? 1, month: c.month ?? 1), window.coversOpeningDay(minute: minute) {
                result = max(result, status(of: date, city: city))
            }
            if window.opens(weekday: p.weekday ?? 1, month: p.month ?? 1), window.coversNextDay(minute: minute) {
                // A night across a change of status, such as into a holiday or into August: no source settles it.
                let opening = status(of: previous, city: city), closing = status(of: date, city: city)
                result = max(result, opening == closing ? opening : .unverified)
            }
        }
        return result
    }

    private func status(of day: Date, city: City) -> State {
        let c = Holidays.calendar.dateComponents([.month, .weekday], from: day)
        if closedMonths.contains(c.month ?? 0) { return .off }
        if silentMonths.contains(c.month ?? 0) { return .unverified }
        if holidays == .included { return .on }
        if Holidays.isPatron(day, city: city) { return .unverified }
        guard Holidays.isNational(day) else { return .on }
        return holidays == .excludedMidweek && c.weekday == 7 ? .unverified : .off
    }
}
