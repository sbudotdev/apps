import AppKit
import SpriteKit
import Testing
@testable import SbuSeasons

/// Il cursore asciuga la pioggia sul vetro (SBU-228): le gocce nel raggio spariscono, resta una scia che la pioggia
/// richiude in `RainTuning.wipeClose` secondi.
@MainActor
struct GlassWipeTests {
    private let size = CGSize(width: 400, height: 300)
    /// Niente pioggia nuova: si guardano solo le gocce messe a mano e la scia.
    private let still = GlassRain(beads: 0, size: 2...2, slide: 50, most: 1000, color: .white)
    /// Pioggia fitta, per vedere la scia che si richiude.
    private let heavy = GlassRain(beads: 4000, size: 0.5...0.6, slide: 50, most: 100_000, color: .white)
    private let center = CGPoint(x: 200, y: 150)

    private func inside(_ glass: GlassDrops, radius: CGFloat = 40) -> Int {
        glass.drops.count { hypot($0.position.x - center.x, $0.position.y - center.y) < radius }
    }

    @Test func aDropInTheRadiusIsWipedOneOutsideStays() {
        var glass = GlassDrops(rain: still)
        glass.bead(at: CGPoint(x: 210, y: 150), radius: 2)
        glass.bead(at: CGPoint(x: 300, y: 150), radius: 2)
        let near = glass.drops[0].id
        glass.step(dt: 0.05, size: size, ledges: [], amount: 1, calm: false, wipe: (center, 40))
        #expect(glass.drops.map(\.position) == [CGPoint(x: 300, y: 150)])
        #expect(glass.wiped == [near])   // chi disegna la fa sparire
    }

    @Test func rightAfterTheWipeNoRainLandsOnTheTrail() {
        var glass = GlassDrops(rain: heavy)
        for _ in 0..<40 { glass.step(dt: 0.05, size: size, ledges: [], amount: 1, calm: false) }
        #expect(inside(glass) > 0)
        glass.step(dt: 0.05, size: size, ledges: [], amount: 1, calm: false, wipe: (center, 40))
        glass.step(dt: 0.05, size: size, ledges: [], amount: 1, calm: false)
        #expect(inside(glass, radius: 35) == 0)
    }

    @Test func theTrailClosesAfterTheExpectedTime() {
        for calm in [false, true] {
            var glass = GlassDrops(rain: heavy)
            for _ in 0..<40 { glass.step(dt: 0.05, size: size, ledges: [], amount: 1, calm: calm) }
            glass.step(dt: 0.05, size: size, ledges: [], amount: 1, calm: calm, wipe: (center, 40))
            // Prima del tempo più corto la scia c'è ancora.
            let early = Int((RainTuning.wipeClose.lowerBound - 0.2) / 0.05)
            for _ in 0..<early { glass.step(dt: 0.05, size: size, ledges: [], amount: 1, calm: calm) }
            #expect(!glass.trail.isEmpty)
            // Dopo quello più lungo è richiusa: la pioggia è tornata a coprirla.
            let rest = Int((RainTuning.wipeClose.upperBound + 0.2) / 0.05) - early
            for _ in 0..<rest { glass.step(dt: 0.05, size: size, ledges: [], amount: 1, calm: calm) }
            #expect(glass.trail.isEmpty)
            #expect(inside(glass) > 5)
        }
    }

    /// Con Riduci movimento la scia non si riempie a poco a poco: resta asciutta e si richiude tutta insieme.
    @Test func withReduceMotionTheTrailClosesAllAtOnce() {
        var glass = GlassDrops(rain: heavy)
        for _ in 0..<40 { glass.step(dt: 0.05, size: size, ledges: [], amount: 1, calm: true) }
        glass.step(dt: 0.05, size: size, ledges: [], amount: 1, calm: true, wipe: (center, 40))
        for _ in 0..<Int((RainTuning.wipeClose.lowerBound - 0.2) / 0.05) {
            glass.step(dt: 0.05, size: size, ledges: [], amount: 1, calm: true)
        }
        #expect(inside(glass, radius: 35) == 0)
    }

    @Test func behindWindowsOnlyTheVisibleDesktopIsWiped() {
        let window = CGRect(x: 100, y: 100, width: 200, height: 100)
        #expect(SeasonScene.wipesGlass(at: CGPoint(x: 150, y: 150), behindWindows: false, covers: [window]))
        #expect(!SeasonScene.wipesGlass(at: CGPoint(x: 150, y: 150), behindWindows: true, covers: [window]))
        #expect(SeasonScene.wipesGlass(at: CGPoint(x: 50, y: 50), behindWindows: true, covers: [window]))
    }

    /// Nella scena: con la pioggia sul vetro il cursore che passa asciuga; fermo no.
    @Test func theCursorPassingOverTheRainWipesIt() throws {
        let scene = SeasonScene(size: size, screenOrigin: .zero, season: Clear())
        scene.setSeason(Rain())
        var pointer = CGPoint(x: -100, y: -100)
        scene.pointerLocation = { pointer }
        var t: TimeInterval = 1
        for _ in 0..<60 { scene.step(at: t); t += 0.05 }
        pointer = CGPoint(x: 150, y: 150)
        scene.step(at: t); t += 0.05
        pointer = CGPoint(x: 160, y: 150)
        scene.step(at: t)
        let model = try #require(scene.glass.model)
        #expect(!model.trail.isEmpty)
    }
}
