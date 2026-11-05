import Foundation

extension Tally {
    /// The made-up count of screenshots and UI tests: 45 minutes blocked today, two hours the best day.
    nonisolated static func sample(now: Date = .now, calendar: Calendar = .current) -> Tally {
        var tally = Tally()
        tally.blockedDay = Day(now, calendar: calendar)
        tally.blockedSeconds = 45 * 60
        tally.record = 2 * 3600
        return tally
    }
}
