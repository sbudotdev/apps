/// The score after a run of points, built by `PadelMatch` replaying them from the start.
///
/// Rules: games to 6 with a two-game lead, a tie-break to 7 (two clear) at 6 all,
/// best of three sets. The serve changes every game; in the tie-break after the first point,
/// then every two points, and the pair that received first serves the next set's first game.
nonisolated struct MatchScore: Equatable, Sendable {
    let deuceRule: DeuceRule
    /// The finished sets, games for each side.
    private(set) var sets: [Pair] = []
    private(set) var games = Pair()
    /// Points in the current game, or in the tie-break.
    private(set) var points = Pair()
    private(set) var isTiebreak = false
    private(set) var server: Side
    private(set) var winner: Side?
    /// What the last point added closed.
    private(set) var lastEvent: MatchEvent?
    private var tiebreakFirstServer: Side

    init(deuceRule: DeuceRule, firstServer: Side) {
        self.deuceRule = deuceRule
        server = firstServer
        tiebreakFirstServer = firstServer
    }

    var setsWon: Pair {
        sets.reduce(into: Pair()) { won, set in won[set.us > set.them ? .us : .them] += 1 }
    }

    /// The game score as it is called: 0, 15, 30, 40, AD; plain numbers in the tie-break.
    func call(for side: Side) -> String {
        let mine = points[side], theirs = points[side.other]
        if isTiebreak { return String(mine) }
        if mine >= 3 && theirs >= 3 { return mine > theirs ? "AD" : "40" }
        return ["0", "15", "30", "40"][min(mine, 3)]
    }

    mutating func add(pointTo side: Side) {
        guard winner == nil else { return }
        points[side] += 1
        let lead = points[side] - points[side.other]
        if isTiebreak {
            if points[side] >= 7 && lead >= 2 {
                winGame(side)
            } else {
                // After the first point, then every two.
                let played = points.us + points.them
                server = (played + 1) / 2 % 2 == 0 ? tiebreakFirstServer : tiebreakFirstServer.other
                lastEvent = .point
            }
            return
        }
        let needed = deuceRule == .goldenPoint ? 1 : 2
        if points[side] >= 4 && lead >= needed {
            winGame(side)
        } else {
            lastEvent = .point
        }
    }

    private mutating func winGame(_ side: Side) {
        let wasTiebreak = isTiebreak
        games[side] += 1
        points = Pair()
        isTiebreak = false
        server = wasTiebreak ? tiebreakFirstServer.other : server.other
        let lead = games[side] - games[side.other]
        if wasTiebreak || (games[side] >= 6 && lead >= 2) {
            sets.append(games)
            games = Pair()
            if setsWon[side] == 2 {
                winner = side
                lastEvent = .match
            } else {
                lastEvent = .set
            }
        } else {
            if games.us == 6 && games.them == 6 {
                isTiebreak = true
                tiebreakFirstServer = server
            }
            lastEvent = .game
        }
    }
}
