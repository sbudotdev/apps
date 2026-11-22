import Foundation
import SbuKit
import Testing
@testable import SbuSquares

struct ChristmasTests {
    nonisolated private static let rome: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Rome")!
        return calendar
    }()

    nonisolated private static func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12, _ minute: Int = 0, _ second: Int = 0) -> Date {
        rome.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute, second: second))!
    }

    @Test(arguments: [
        (date(2026, 11, 30, 23, 59, 59), false),
        (date(2026, 12, 1, 0, 0, 0), true),
        (date(2026, 12, 10), true),
        (date(2027, 1, 6, 23, 59, 59), true),
        (date(2027, 1, 7, 0, 0, 0), false),
        (date(2026, 11, 17), false),
    ])
    func theThemeIsOnFromTheFirstOfDecemberToEpiphany(date: Date, isOn: Bool) {
        let accents = PieceTone.accents(in: SbuSeason.active(on: date, in: Self.rome))
        #expect((accents == PieceTone.christmas) == isOn)
        #expect((accents == PieceTone.everyDay) == !isOn)
    }

    @Test func theThemeKeepsEightTones() {
        #expect(PieceTone.christmas.count == Piece.toneCount)
        #expect(Set(PieceTone.christmas).count == Piece.toneCount)
    }

    @Test(arguments: [
        (date(2026, 12, 23, 23, 59, 59), nil),
        (date(2026, 12, 24, 0, 0, 0), 20_261_224),
        (date(2026, 12, 25), 20_261_225),
        (date(2026, 12, 26, 23, 59, 59), 20_261_226),
        (date(2026, 12, 27, 0, 0, 0), nil),
        (date(2026, 12, 10), nil),
        (date(2027, 6, 25), nil),
    ] as [(Date, UInt64?)])
    func theSpecialGameComesOnlyFromTheTwentyFourthToTheTwentySixth(date: Date, seed: UInt64?) {
        #expect(ChristmasGame.seed(on: date, in: Self.rome) == seed)
        #expect(ChristmasGame.game(on: date, in: Self.rome, recordToBeat: 0)?.seed == seed)
    }

    @Test func theSpecialGameIsTheSameOnEveryRun() throws {
        let first = try #require(ChristmasGame.game(on: Self.date(2026, 12, 25, 9), in: Self.rome, recordToBeat: 0))
        let second = try #require(ChristmasGame.game(on: Self.date(2026, 12, 25, 22), in: Self.rome, recordToBeat: 0))
        #expect(first == second)
        #expect(first.leftInHand == second.leftInHand)
    }

    @Test func theSpecialGameStartsWithTheTreeOnTheBoard() throws {
        let game = try #require(ChristmasGame.game(on: Self.date(2026, 12, 24), in: Self.rome, recordToBeat: 0))
        #expect(game.board == ChristmasGame.tree)
        #expect(game.board.filledCount == 14)
        #expect(!game.isOver)
        #expect(game.score == 0)
    }

    private static func freshDefaults() -> UserDefaults {
        let suite = "squares.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    @Test func aNewGameOnChristmasDayIsTheSpecialGame() {
        var today = Self.date(2026, 11, 17)
        let store = GameStore(defaults: Self.freshDefaults(), now: { today })
        #expect(store.game.board.filledCount == 0)

        today = Self.date(2026, 12, 25)
        store.startNewGame()
        #expect(store.game.seed == ChristmasGame.seed(on: today))
        #expect(store.game.board == ChristmasGame.tree)

        today = Self.date(2026, 12, 28)
        store.startNewGame()
        #expect(store.game.board.filledCount == 0)
    }

    @Test func theChristmasGameKeepsTheAssistsAndTheShapesLeftInHand() {
        let defaults = Self.freshDefaults()
        defaults.set(Game.maxAssists, forKey: "assists")
        defaults.set([3, 4], forKey: "lastGame.leftInHand")
        let store = GameStore(defaults: defaults, now: { Self.date(2026, 12, 25) })
        store.startNewGame()
        for _ in 0..<500 where !store.game.isOver {
            let move = (0..<3).lazy.compactMap { slot in
                store.game.piece(in: slot).flatMap { piece in
                    Board.allCells.first { store.game.board.canPlace(piece, at: $0) }.map { (slot, $0) }
                }
            }.first
            guard let (slot, cell) = move else { break }
            store.place(slot: slot, at: cell)
        }
        store.endGame()
        #expect(store.game.isOver)
        #expect(defaults.integer(forKey: "assists") == Game.maxAssists)
        #expect(defaults.array(forKey: "lastGame.leftInHand") as? [Int] == [3, 4])
    }

    @Test(arguments: [UInt64(20_261_225), 20_271_224, 20_261_226])
    func christmasSeedsAreRecognised(seed: UInt64) {
        #expect(ChristmasGame.isChristmasSeed(seed))
    }

    @Test(arguments: [UInt64(20_261_223), 20_261_227, 20_261_125, 7, 1_220_261_225])
    func otherSeedsAreNot(seed: UInt64) {
        #expect(!ChristmasGame.isChristmasSeed(seed))
    }
}
