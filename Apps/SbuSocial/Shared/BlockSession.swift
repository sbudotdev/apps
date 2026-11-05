import DeviceActivity
import Foundation

/// A Sessione: everything but the allowed apps is blocked between two hours on the chosen days,
/// starting and ending by itself.
nonisolated struct BlockSession: Codable, Equatable, Identifiable {
    var id = UUID()
    var name: String
    /// Minutes after midnight.
    var start: Int
    var end: Int
    /// Calendar weekdays, 1 Sunday to 7 Saturday: a night belongs to the day it starts on.
    var days: Set<Int> = Set(1...7)
    /// The points a finished Sessione gives.
    var xp = 10
    var isOn = true

    /// Screen Time schedules last at least 15 minutes.
    static let minimumMinutes = 15

    /// The one-tap ideas, with the hours and points of the Original's.
    static var presets: [BlockSession] {
        [
            BlockSession(name: String(localized: "Lavoro"), start: 9 * 60 + 30, end: 17 * 60, days: [2, 3, 4, 5, 6], xp: 25),
            BlockSession(name: String(localized: "Mattina"), start: 6 * 60, end: 8 * 60 + 30, xp: 25),
            BlockSession(name: String(localized: "Notte"), start: 22 * 60, end: 5 * 60, xp: 25),
            BlockSession(name: String(localized: "Cena"), start: 18 * 60 + 30, end: 19 * 60 + 30, xp: 10),
            BlockSession(name: String(localized: "Fine settimana"), start: 12 * 60 + 30, end: 18 * 60, days: [1, 7], xp: 25),
            BlockSession(name: String(localized: "Allenamento"), start: 7 * 60 + 30, end: 8 * 60 + 30, xp: 10),
            BlockSession(name: String(localized: "Meditazione"), start: 9 * 60, end: 9 * 60 + 15, xp: 1),
        ]
    }

    var activity: DeviceActivityName {
        .init("session-\(id.uuidString)")
    }

    /// How long it lasts, across midnight if it ends before it starts.
    var minutes: Int {
        (end - start + 24 * 60) % (24 * 60)
    }

    var isValid: Bool {
        minutes >= Self.minimumMinutes
    }

    /// Every day at its hours: the days are checked when it runs, since one schedule per weekday
    /// would spend seven of the 20 Screen Time allows.
    var schedule: DeviceActivitySchedule {
        DeviceActivitySchedule(intervalStart: DateComponents(hour: start / 60, minute: start % 60),
                               intervalEnd: DateComponents(hour: end / 60, minute: end % 60),
                               repeats: true)
    }

    /// Whether it blocks at `date`: on, inside its hours, and started on one of its days.
    func isRunning(at date: Date, calendar: Calendar = .current) -> Bool {
        guard isOn else { return false }
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        let minute = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
        let today = Day(date, calendar: calendar)
        if start < end {
            return minute >= start && minute < end && days.contains(today.weekday)
        }
        // Across midnight: tonight's part, or the end of the night that started yesterday.
        return minute >= start && days.contains(today.weekday)
            || minute < end && days.contains(Day(ordinal: today.ordinal - 1).weekday)
    }
}
