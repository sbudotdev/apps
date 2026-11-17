import Foundation

/// The game of the day from 24 to 26 December: a tree on the board and a public seed, the date
/// as yyyymmdd, so everyone gets the same game that day.
nonisolated enum ChristmasGame {
    /// The crown in tone 1, the trunk in tone 2: green and gold in the Christmas palette.
    static let tree: Board = {
        var board = Board()
        let crown = Piece("........", "...##...", "..####..", ".######.").cells
        let trunk = Piece("........", "........", "........", "........", "...##...").cells
        board.apply(Placement(covered: crown, rows: [], columns: []), tone: 1)
        board.apply(Placement(covered: trunk, rows: [], columns: []), tone: 2)
        return board
    }()

    /// The day's seed, 20261225 on Christmas 2026, or `nil` outside 24–26 December in the time
    /// zone of `calendar`, on Gregorian days like `SbuSeason`.
    static func seed(on date: Date, in calendar: Calendar = .current) -> UInt64? {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = calendar.timeZone
        let day = gregorian.dateComponents([.year, .month, .day], from: date)
        guard day.month == 12, let year = day.year, let dayOfMonth = day.day, (24...26).contains(dayOfMonth) else { return nil }
        return UInt64(year * 10_000 + 1_200 + dayOfMonth)
    }

    /// The day's game, or `nil` outside 24–26 December. It leaves out nothing the last game left
    /// in hand and carries no assists, so it deals the same for everyone.
    static func game(on date: Date, in calendar: Calendar = .current, recordToBeat: Int) -> Game? {
        seed(on: date, in: calendar).map { Game(seed: $0, recordToBeat: recordToBeat, board: tree) }
    }
}
