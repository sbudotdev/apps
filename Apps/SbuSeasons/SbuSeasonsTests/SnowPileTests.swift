import Testing
import CoreGraphics
@testable import SbuSeasons

@MainActor
struct SnowPileTests {
    /// Un mucchio piatto (angoli vivi) da 100 pt, pieno fino all'altezza massima.
    private func fullPile(maxHeight: CGFloat) -> SnowPile {
        let pile = SnowPile(minX: 0, width: 100, baseY: 500, cornerRadius: 0, maxHeight: maxHeight)
        for _ in 0..<200 {
            for x in stride(from: CGFloat(1), to: 100, by: 2) { pile.add(atX: x, radius: 1, growth: 1) }
        }
        return pile
    }

    @Test func snowNeverGrowsPastTheMaximumHeight() {
        let pile = fullPile(maxHeight: 20)
        #expect(pile.heights.allSatisfy { $0 <= 20 })
        #expect(pile.heights.contains { $0 > 19 })
    }

    @Test func loweringTheMaximumHeightLowersTheSnowAlreadyThere() {
        let pile = fullPile(maxHeight: 20)
        pile.maxHeight = 5
        pile.settle()
        #expect(pile.heights.allSatisfy { $0 <= 5 })
    }
}
