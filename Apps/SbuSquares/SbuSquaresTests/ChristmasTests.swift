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

    @Test func aNewGameOnChristmasDayIsTheSpecialGame() {
        let suite = "squares.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let store = GameStore(defaults: defaults, now: Self.date(2026, 11, 17))
        #expect(store.game.board.filledCount == 0)

        store.startNewGame(now: Self.date(2026, 12, 25))
        #expect(store.game.seed == ChristmasGame.seed(on: Self.date(2026, 12, 25)))
        #expect(store.game.board == ChristmasGame.tree)

        store.startNewGame(now: Self.date(2026, 12, 27))
        #expect(store.game.board.filledCount == 0)
    }
}
