/// The wait before the text starts moving.
nonisolated struct Countdown: Sendable, Equatable {
    static let choices = [0, 3, 5, 10]

    let seconds: Int

    /// Whole seconds left to show, or nil once it is over.
    func remaining(after elapsed: Double) -> Int? {
        let left = Double(seconds) - elapsed
        return left > 0 ? Int(left.rounded(.up)) : nil
    }
}
