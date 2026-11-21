/// Follows a reader through the script: given what speech recognition heard so far,
/// returns how many script words have been read. Pure, so it is tested without a microphone.
///
/// It aligns the last spoken words against a window of the script around the current
/// position (local alignment, Smith-Waterman style), so skipped words, repeated words,
/// small recognition errors and improvised sentences don't throw it off. It never moves back.
nonisolated struct ScriptAligner: Sendable {
    let script: [String]
    let window: Int
    private(set) var position: Int

    /// Spoken words considered at each update.
    private let tailLength = 10
    /// Only alignments ending on one of the last few spoken words count.
    private let recentRows = 3

    init(script: [String], position: Int = 0, window: Int = 40) {
        self.script = script
        self.window = window
        self.position = min(max(position, 0), script.count)
    }

    mutating func reset(to position: Int) {
        self.position = min(max(position, 0), script.count)
    }

    /// `spoken` is the normalized transcript so far (or its recent end).
    @discardableResult
    mutating func update(spoken: [String]) -> Int {
        let tail = Array(spoken.suffix(tailLength))
        guard !tail.isEmpty, position < script.count else { return position }

        let lower = max(0, position - tailLength * 2)
        let upper = min(script.count, position + window)
        let columns = upper - lower
        guard columns > 0 else { return position }

        // dp[i][j]: best local alignment ending at tail[i-1] and script[lower + j-1].
        var dp = Array(repeating: Array(repeating: 0, count: columns + 1), count: tail.count + 1)
        var best: (score: Int, row: Int, index: Int)?
        for i in 1...tail.count {
            for j in 1...columns {
                let index = lower + j - 1
                let match = Self.score(tail[i - 1], script[index])
                dp[i][j] = max(0, dp[i - 1][j - 1] + match, dp[i - 1][j] - 1, dp[i][j - 1] - 1)

                guard match > 0, i > tail.count - recentRows, index >= position else { continue }
                let score = dp[i][j]
                // A lone word only counts when it is exactly the next one.
                let accepted = score >= 4 || (score >= 2 && index == position)
                guard accepted else { continue }
                if let current = best {
                    let better = score > current.score
                        || (score == current.score && i > current.row)
                        || (score == current.score && i == current.row && index < current.index)
                    if better { best = (score, i, index) }
                } else {
                    best = (score, i, index)
                }
            }
        }
        if let best { position = best.index + 1 }
        return position
    }

    /// 2 for the same word, 1 for a close one (recognition slip), -1 otherwise.
    private static func score(_ spoken: String, _ written: String) -> Int {
        if spoken == written { return 2 }
        let length = max(spoken.count, written.count)
        guard min(spoken.count, written.count) >= 4 else { return -1 }
        let similarity = 1 - Double(distance(spoken, written)) / Double(length)
        return similarity >= 0.75 ? 1 : -1
    }

    private static func distance(_ a: String, _ b: String) -> Int {
        let a = Array(a), b = Array(b)
        var previous = Array(0...b.count)
        for i in 1...a.count {
            var current = [i] + Array(repeating: 0, count: b.count)
            for j in 1...b.count {
                current[j] = min(previous[j] + 1, current[j - 1] + 1, previous[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1))
            }
            previous = current
        }
        return previous[b.count]
    }
}
