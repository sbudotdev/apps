import Foundation
import Testing
@testable import SbuPadel

struct PadelMatchTests {
    /// A match after the given points, with "u" for us and "t" for them.
    private func match(_ points: String, rule: DeuceRule = .goldenPoint, server: Side = .us) -> PadelMatch {
        var match = PadelMatch(deuceRule: rule, firstServer: server)
        for character in points where character != " " {
            match.point(to: character == "u" ? .us : .them)
        }
        return match
    }

    /// A game won by `side` to love.
    private func game(_ side: Side) -> String { side == .us ? "uuuu" : "tttt" }

    private func games(_ sides: [Side]) -> String { sides.map(game).joined() }

    @Test func gameGoesZeroFifteenThirtyFortyThenWins() {
        #expect(match("").score.call(for: .us) == "0")
        #expect(match("u").score.call(for: .us) == "15")
        #expect(match("uu").score.call(for: .us) == "30")
        #expect(match("uuu").score.call(for: .us) == "40")
        let won = match("uuuu").score
        #expect(won.games == Pair(us: 1, them: 0))
        #expect(won.call(for: .us) == "0")
        #expect(won.lastEvent == .game)
    }

    @Test func goldenPointWinsTheGameAtFortyAll() {
        let score = match("uuuttt t").score
        #expect(score.games == Pair(us: 0, them: 1))
    }

    @Test func advantagesNeedTwoPointsFromFortyAll() {
        let advantage = match("uuuttt u", rule: .advantages).score
        #expect(advantage.games == Pair())
        #expect(advantage.call(for: .us) == "AD")
        #expect(advantage.call(for: .them) == "40")
        #expect(match("uuuttt ut", rule: .advantages).score.call(for: .us) == "40")
        #expect(match("uuuttt ut uu", rule: .advantages).score.games == Pair(us: 1, them: 0))
    }

    @Test func setSixFour() {
        let score = match(games([.us, .them, .us, .them, .us, .them, .us, .them, .us, .us])).score
        #expect(score.sets == [Pair(us: 6, them: 4)])
        #expect(score.games == Pair())
        #expect(score.lastEvent == .set)
    }

    @Test func fiveAllNeedsSevenFive() {
        let fiveAll = games([.us, .them, .us, .them, .us, .them, .us, .them, .us, .them])
        let sixFive = match(fiveAll + game(.us)).score
        #expect(sixFive.sets.isEmpty)
        #expect(sixFive.games == Pair(us: 6, them: 5))
        #expect(match(fiveAll + games([.us, .us])).score.sets == [Pair(us: 7, them: 5)])
    }

    @Test func sixAllPlaysATiebreakToSeven() {
        let sixAll = games([.us, .them, .us, .them, .us, .them, .us, .them, .us, .them, .us, .them])
        let tiebreak = match(sixAll + "uuuuuu").score
        #expect(tiebreak.isTiebreak)
        #expect(tiebreak.call(for: .us) == "6")
        let won = match(sixAll + "uuuuuuu").score
        #expect(won.sets == [Pair(us: 7, them: 6)])
        #expect(won.isTiebreak == false)
    }

    @Test func tiebreakNeedsTwoClearPoints() {
        let sixAll = games([.us, .them, .us, .them, .us, .them, .us, .them, .us, .them, .us, .them])
        let points = String(repeating: "ut", count: 6) + "u"
        #expect(match(sixAll + points).score.sets.isEmpty)
        #expect(match(sixAll + points + "u").score.sets == [Pair(us: 7, them: 6)])
    }

    @Test func matchTwoSetsToLove() {
        let set = games(Array(repeating: .us, count: 6))
        let score = match(set + set).score
        #expect(score.winner == .us)
        #expect(score.setsWon == Pair(us: 2, them: 0))
        #expect(score.lastEvent == .match)
    }

    @Test func matchTwoSetsToOne() {
        let ours = games(Array(repeating: .us, count: 6))
        let theirs = games(Array(repeating: .them, count: 6))
        let afterTwo = match(ours + theirs).score
        #expect(afterTwo.winner == nil)
        #expect(afterTwo.setsWon == Pair(us: 1, them: 1))
        let score = match(theirs + ours + theirs).score
        #expect(score.winner == .them)
        #expect(score.setsWon == Pair(us: 1, them: 2))
    }

    @Test func noPointsAfterTheMatchIsOver() {
        let set = games(Array(repeating: .us, count: 6))
        var finished = match(set + set)
        let points = finished.points
        finished.point(to: .them)
        #expect(finished.points == points)
    }

    @Test func serveChangesEveryGame() {
        #expect(match("").score.server == .us)
        #expect(match("uuu").score.server == .us)
        #expect(match("uuuu").score.server == .them)
        #expect(match("uuuu tttt").score.server == .us)
        #expect(match("", server: .them).score.server == .them)
    }

    @Test func tiebreakServeChangesAfterOnePointThenEveryTwo() {
        // 12 games: the serve alternates back to us for the tie-break.
        let sixAll = games([.us, .them, .us, .them, .us, .them, .us, .them, .us, .them, .us, .them])
        #expect(match(sixAll).score.server == .us)
        let expected: [Side] = [.them, .them, .us, .us, .them, .them, .us]
        for (played, server) in expected.enumerated() {
            let points = String(repeating: "ut", count: 6).prefix(played + 1)
            #expect(match(sixAll + points).score.server == server, "after \(played + 1) points")
        }
        // The pair that received first in the tie-break serves the next set.
        #expect(match(sixAll + "uuuuuuu").score.server == .them)
    }

    @Test func undoGoesBackAcrossAGame() {
        var won = match("uuuu")
        won.undo()
        #expect(won.score.games == Pair())
        #expect(won.score.call(for: .us) == "40")
        #expect(won.score.server == .us)
    }

    @Test func undoGoesBackAcrossASetAndToTheStart() {
        var set = match(games(Array(repeating: .us, count: 6)))
        set.undo()
        #expect(set.score.sets.isEmpty)
        #expect(set.score.games == Pair(us: 5, them: 0))
        #expect(set.score.call(for: .us) == "40")
        for _ in 0..<30 { set.undo() }
        #expect(set.points.isEmpty)
        #expect(set.score == match("").score)
    }

    @Test func scoreboardSavesEveryPoint() throws {
        let defaults = try #require(UserDefaults(suiteName: "padel-\(UUID())"))
        let board = Scoreboard(defaults: defaults)
        board.point(to: .us)
        board.point(to: .them)
        #expect(Scoreboard(defaults: defaults).match.points == [.us, .them])
        board.undo()
        #expect(Scoreboard(defaults: defaults).match.points == [.us])
    }

    @Test func scoreboardCountsPointsGamesAndSetsApart() throws {
        let defaults = try #require(UserDefaults(suiteName: "padel-\(UUID())"))
        let board = Scoreboard(defaults: defaults)
        for _ in 0..<4 { board.point(to: .us) }
        #expect(board.pointTaps == 3)
        #expect(board.gameTaps == 1)
        for _ in 0..<20 { board.point(to: .us) }
        #expect(board.setTaps == 1)
    }

    @Test func rulesChangeOnlyBeforeTheFirstPoint() throws {
        let defaults = try #require(UserDefaults(suiteName: "padel-\(UUID())"))
        let board = Scoreboard(defaults: defaults)
        board.setDeuceRule(.advantages)
        board.setFirstServer(.them)
        board.point(to: .us)
        board.setDeuceRule(.goldenPoint)
        board.setFirstServer(.us)
        #expect(board.match.deuceRule == .advantages)
        #expect(board.match.firstServer == .them)
        board.newMatch()
        #expect(board.match.points.isEmpty)
        #expect(board.match.deuceRule == .advantages)
    }
}
