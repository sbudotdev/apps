/// Scroll position of the prompter text, in points from the top.
nonisolated struct ScrollEngine: Sendable, Equatable {
    static let speedRange: ClosedRange<Double> = 10...300
    static let speedStep: Double = 10

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

    /// Eases toward `target` (voice mode): covers most of the gap in about a third of a second.
    mutating func approach(_ target: Double, by seconds: Double) {
        let factor = min(1, seconds * 8)
        offset = clamped(offset + (target - offset) * factor)
    }

    mutating func rewind() { offset = 0 }
    mutating func faster() { speed += Self.speedStep }
    mutating func slower() { speed -= Self.speedStep }

    private func clamped(_ value: Double) -> Double {
        min(max(value, 0), max(maxOffset, 0))
    }
}
