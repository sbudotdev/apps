import Foundation
import ManagedSettings

/// An Intenzione: one app you open at most `maxOpens` times a day, `minutes` each time, on the
/// chosen weekdays. On those days the app stays shielded except while an opening lasts.
nonisolated struct Intention: Codable, Equatable, Identifiable {
    var id = UUID()
    /// The app, as Screen Time hands it over. Empty only in tests and previews.
    var app: ApplicationToken?
    /// The app's name, which only the Shield can read; kept for the notification.
    var name: String?
    var maxOpens = 10
    var minutes = 10
    /// Calendar weekdays, 1 Sunday to 7 Saturday.
    var days: Set<Int> = Set(1...7)
    /// The day `opens` counts.
    var opensDay: Day?
    var opens = 0
    /// The running opening's end.
    var unlockedUntil: Date?

    static let lengths = [1, 3, 5, 7, 10, 15, 20, 30]

    /// Openings on `day`: yesterday's count is gone.
    func opens(on day: Day) -> Int {
        opensDay == day ? opens : 0
    }

    /// Whether the Shield covers the app now: one of its days, and no opening running.
    func isLocked(now: Date, calendar: Calendar = .current) -> Bool {
        guard days.contains(Day(now, calendar: calendar).weekday) else { return false }
        return (unlockedUntil ?? .distantPast) <= now
    }

    /// Counts an opening and lifts the Shield for `minutes`.
    /// - Returns: `true` when this opening goes beyond `maxOpens`.
    @discardableResult
    mutating func open(now: Date, calendar: Calendar = .current) -> Bool {
        let today = Day(now, calendar: calendar)
        opens = opens(on: today) + 1
        opensDay = today
        unlockedUntil = now.addingTimeInterval(TimeInterval(minutes * 60))
        return opens > maxOpens
    }
}
