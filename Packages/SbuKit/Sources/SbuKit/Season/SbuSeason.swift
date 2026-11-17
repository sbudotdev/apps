import Foundation

/// A time of year when the apps may dress up, shipped in the build and switched on by the date
/// alone (ADR-0023): no network, nothing saved.
nonisolated public enum SbuSeason: String, CaseIterable, Sendable {
    /// From 1 December to 6 January, both included.
    case christmas

    /// Returns the season active on `date` in the time zone of `calendar`, or `nil` outside every season.
    ///
    /// Days are always Gregorian, so a person on another calendar system still gets Christmas
    /// on 1 December to 6 January of their time zone.
    public static func active(on date: Date, in calendar: Calendar = .current) -> SbuSeason? {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = calendar.timeZone
        let day = gregorian.dateComponents([.month, .day], from: date)
        switch (day.month, day.day) {
        case (12, _): return .christmas
        case (1, let dayOfMonth?) where dayOfMonth <= 6: return .christmas
        default: return nil
        }
    }
}
