/// Scroll position of the prompter text, in points from the top.
nonisolated struct ScrollEngine: Sendable, Equatable {
    /// Faster and slower move between these, finer at the slow end where a step is felt most.
    static let speedSteps: [Double] = [4, 6, 8, 10, 12, 15, 20, 25, 30, 35, 40, 50, 60, 70, 80, 100, 120, 150, 180, 220, 260, 300]
    static let speedRange: ClosedRange<Double> = speedSteps[0]...speedSteps[speedSteps.count - 1]

    private(set) var offset: Double = 0

    /// Points per second.
    var speed: Double {
        didSet { speed = min(max(speed, Self.speedRange.lowerBound), Self.speedRange.upperBound) }
    }

    var maxOffset: Double {
        didSet { offset = clamped(offset) }
    }

    init(speed: Double, maxOffset: Double) {
        self.speed = min(max(speed, Self.speedRange.lowerBound), Self.speedRange.upperBound)
        self.maxOffset = max(maxOffset, 0)
    }

    var isAtEnd: Bool { offset >= maxOffset }

    mutating func advance(by seconds: Double) {
        offset = clamped(offset + speed * seconds)
    }

    mutating func scroll(by points: Double) {
        offset = clamped(offset + points)
    }

    mutating func scroll(to points: Double) {
        offset = clamped(points)
    }

    /// Eases toward `target` (voice mode). `rate` 8 covers most of the gap in about a third of a second;
    /// lower is a slower, smoother glide.
    mutating func approach(_ target: Double, by seconds: Double, rate: Double = 8) {
        let factor = min(1, seconds * rate)
        offset = clamped(offset + (target - offset) * factor)
    }

    mutating func rewind() { offset = 0 }
    mutating func faster() { speed = Self.speedSteps.first { $0 > speed } ?? Self.speedRange.upperBound }
    mutating func slower() { speed = Self.speedSteps.last { $0 < speed } ?? Self.speedRange.lowerBound }

    private func clamped(_ value: Double) -> Double {
        min(max(value, 0), max(maxOffset, 0))
    }
}
