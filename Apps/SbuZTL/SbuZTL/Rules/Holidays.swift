import Foundation

/// Italian public holidays, always on the Rome clock whatever the phone says.
nonisolated enum Holidays {
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Rome") ?? .gmt
        return calendar
    }()

    static func isNational(_ date: Date) -> Bool {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        guard let year = c.year, let month = c.month, let day = c.day else { return false }
        let fixed = [(1, 1), (1, 6), (4, 25), (5, 1), (6, 2), (8, 15), (11, 1), (12, 8), (12, 25), (12, 26)]
        if fixed.contains(where: { $0 == (month, day) }) { return true }
        let easter = easterSunday(year: year)
        guard let sunday = calendar.date(from: DateComponents(year: year, month: easter.month, day: easter.day)),
              let monday = calendar.date(byAdding: .day, value: 1, to: sunday) else { return false }
        return calendar.isDate(date, inSameDayAs: sunday) || calendar.isDate(date, inSameDayAs: monday)
    }

    /// The patron saint's day: a holiday for the city, not always for its traffic acts.
    static func isPatron(_ date: Date, city: City) -> Bool {
        let c = calendar.dateComponents([.month, .day], from: date)
        return switch city {
        case .milano: c.month == 12 && c.day == 7
        case .firenze: c.month == 6 && c.day == 24
        case .bologna: c.month == 10 && c.day == 4
        case .roma: c.month == 6 && c.day == 29
        case .torino: c.month == 6 && c.day == 24
        }
    }

    /// Meeus/Jones/Butcher, for the Gregorian calendar.
    static func easterSunday(year: Int) -> (month: Int, day: Int) {
        let a = year % 19, b = year / 100, c = year % 100
        let d = b / 4, e = b % 4, f = (b + 8) / 25, g = (b - f + 1) / 3
        let h = (19 * a + b - d - g + 15) % 30
        let i = c / 4, k = c % 4
        let l = (32 + 2 * e + 2 * i - h - k) % 7
        let m = (a + 11 * h + 22 * l) / 451
        let n = h + l - 7 * m + 114
        return (n / 31, n % 31 + 1)
    }
}
