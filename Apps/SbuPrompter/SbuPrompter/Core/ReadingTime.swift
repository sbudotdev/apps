/// How long a script takes to read aloud at an even pace, for the library and the editor.
nonisolated enum ReadingTime {
    /// Words per minute of a calm spoken delivery, in Italian and English alike.
    static let wordsPerMinute = 140.0

    /// Rounded up to 10 seconds; zero words, zero time.
    static func duration(words: Int) -> Duration {
        guard words > 0 else { return .zero }
        let seconds = Double(words) / wordsPerMinute * 60
        return .seconds(Int((seconds / 10).rounded(.up)) * 10)
    }

    /// "1 min, 30 sec" style, the two largest units only.
    static func text(words: Int) -> String {
        duration(words: words).formatted(.units(allowed: [.hours, .minutes, .seconds], width: .abbreviated, maximumUnitCount: 2))
    }
}
