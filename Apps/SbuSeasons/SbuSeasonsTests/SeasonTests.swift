import AppKit
import SpriteKit
import Testing
@testable import SbuSeasons

/// Una stagione finta: il motore deve prendere da lei forma, colore e caduta.
private final class FakeSeason: Season {
    let id = "fake"
    let title = "Finta"
    let symbol = "circle"
    let pileColor = NSColor(srgbRed: 0.8, green: 0.2, blue: 0.1, alpha: 1)
    let texture = SKTexture()
    private(set) var particlesMade = 0

    func makeTexture() -> SKTexture { texture }

    func particle(depth: CGFloat) -> Particle {
        particlesMade += 1
        return Particle(radius: 7, alpha: 0.5, fallSpeed: 40, swayAmplitude: 10, swayFrequency: 0.5)
    }
}

@MainActor
struct SeasonTests {
    private let size = CGSize(width: 400, height: 300)

    @Test func theEngineDrawsTheParticlesOfTheChosenSeason() {
        let fake = FakeSeason()
        let scene = SeasonScene(size: size, screenOrigin: .zero, season: Snow())
        scene.setSeason(fake)

        let sprites = scene.children.compactMap { $0 as? SKSpriteNode }
        #expect(fake.particlesMade > 0)
        #expect(sprites.count == fake.particlesMade)
        #expect(sprites.allSatisfy { $0.texture === fake.texture && $0.alpha == 0.5 })
        #expect(sprites.allSatisfy { $0.size.width == 14 * Settings.shared.values.flakeSize })
    }

    @Test func theSettledParticlesTakeTheColorOfTheSeason() {
        let fake = FakeSeason()
        let scene = SeasonScene(size: size, screenOrigin: .zero, season: fake)
        let edge = WindowEdge(id: 1, rect: CGRect(x: 0, y: 0, width: 200, height: 100), visible: [0...200])
        scene.updateWindows([edge], dock: nil, ceiling: 1000)

        let piles = scene.children.compactMap { $0 as? SKShapeNode }
        #expect(piles.count == 1)
        #expect(piles.first?.fillColor == fake.pileColor)

        scene.setSeason(Snow())
        #expect(piles.first?.fillColor == Snow().pileColor)
    }

    @Test func snowIsTheFirstSeasonAndEveryIdIsUnique() {
        #expect(Seasons.all.first?.id == Snow.id)
        #expect(Set(Seasons.all.map(\.id)).count == Seasons.all.count)
    }

    @Test func anUnknownSavedSeasonFallsBackToSnow() {
        #expect(Seasons.named("estate-del-2099").id == Snow.id)
    }
}
