import Foundation
import Observation

/// The match on screen, saved after every change so it survives the app closing.
@Observable
final class Scoreboard {
    private(set) var match: PadelMatch {
        didSet { save() }
    }
    /// Counts up with every point, game and set, to drive the matching haptic.
    private(set) var pointTaps = 0
    private(set) var gameTaps = 0
    private(set) var setTaps = 0

    private let defaults: UserDefaults
    private static let key = "match"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        match = defaults.data(forKey: Self.key).flatMap { try? JSONDecoder().decode(PadelMatch.self, from: $0) } ?? PadelMatch()
    }

    var score: MatchScore { match.score }

    func point(to side: Side) {
        guard score.winner == nil else { return }
        match.point(to: side)
        switch match.score.lastEvent {
        case .point: pointTaps += 1
        case .game: gameTaps += 1
        case .set, .match: setTaps += 1
        case nil: break
        }
    }

    func undo() { match.undo() }

    func newMatch() {
        match = PadelMatch(deuceRule: match.deuceRule, firstServer: match.firstServer)
    }

    /// Only before the first point.
    func setDeuceRule(_ rule: DeuceRule) {
        guard match.hasStarted == false else { return }
        match.deuceRule = rule
    }

    /// Only before the first point.
    func setFirstServer(_ side: Side) {
        guard match.hasStarted == false else { return }
        match.firstServer = side
    }

    private func save() {
        defaults.set(try? JSONEncoder().encode(match), forKey: Self.key)
    }
}
