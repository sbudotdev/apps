import Foundation

extension Tally {
    /// The made-up count of screenshots and UI tests: 45 minutes blocked today, two hours the best
    /// day, a Serie of four days after one that broke, and the tip already read.
    nonisolated static func sample(now: Date = .now, calendar: Calendar = .current) -> Tally {
        var tally = Tally()
        tally.blockedDay = Day(now, calendar: calendar)
        tally.blockedSeconds = 45 * 60
        tally.record = 2 * 3600
        let today = Day(now, calendar: calendar)
        tally.firstDay = Day(ordinal: today.ordinal - 6)
        tally.exceededDays = [Day(ordinal: today.ordinal - 4)]
        tally.blockXP = 60
        tally.complete(.tip, on: today)
        return tally
    }
}
