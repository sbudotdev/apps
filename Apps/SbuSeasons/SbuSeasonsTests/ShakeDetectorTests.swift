import CoreGraphics
import Foundation
import Testing
@testable import SbuSeasons

/// Scuotere: avanti e indietro più volte, in fretta. Un movimento normale non conta.
struct ShakeDetectorTests {
    /// Punti avanti e indietro in orizzontale, `step` secondi l'uno dall'altro.
    private func feed(_ detector: inout ShakeDetector, xs: [CGFloat], step: TimeInterval) -> Bool {
        var shaken = false
        for (i, x) in xs.enumerated() where detector.add(CGPoint(x: x, y: 100), at: TimeInterval(i) * step) {
            shaken = true
        }
        return shaken
    }

    @Test func backAndForthQuicklyIsAShake() {
        var detector = ShakeDetector()
        #expect(feed(&detector, xs: [0, 80, 0, 80, 0, 80, 0], step: 0.08))
    }

    @Test func aLongStraightMoveIsNot() {
        var detector = ShakeDetector()
        #expect(!feed(&detector, xs: stride(from: 0, through: 1200, by: 60).map { $0 }, step: 0.02))
    }

    @Test func slowBackAndForthIsNot() {
        var detector = ShakeDetector()
        #expect(!feed(&detector, xs: [0, 80, 0, 80, 0, 80, 0], step: 0.6))
    }

    @Test func tinyWobblesAreNot() {
        var detector = ShakeDetector()
        #expect(!feed(&detector, xs: [0, 10, 0, 10, 0, 10, 0, 10, 0], step: 0.05))
    }

    @Test func aWindowShakenBetweenTwoReadsIsFound() {
        var shakes = WindowShakes()
        func edge(_ x: CGFloat) -> WindowEdge {
            WindowEdge(id: 7, rect: CGRect(x: x, y: 100, width: 300, height: 200), visible: [x...(x + 300)])
        }
        var found: Set<CGWindowID> = []
        // Le finestre si leggono 8 volte al secondo.
        for (i, x) in [0, 90, 0, 90, 0, 90].enumerated() {
            found.formUnion(shakes.update([edge(CGFloat(x)), WindowEdge(id: 8, rect: .zero, visible: [])],
                                          at: TimeInterval(i) * Tuning.windowRefreshInterval))
        }
        #expect(found == [7])
    }
}
