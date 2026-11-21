import AppKit
import SpriteKit
import Testing
@testable import SbuSeasons

/// Una stagione con particelle che girano, si ribaltano e hanno un colore loro.
private struct SpinningSeason: Season {
    let id = "spinning"
    let title = "Che gira"
    let symbol = "circle"
    let pileColor = NSColor.orange
    var pileGrowth: ClosedRange<CGFloat> { 0...0 }
    static let tint = NSColor(srgbRed: 0.7, green: 0.3, blue: 0.1, alpha: 1)

    func makeTexture() -> SKTexture { SKTexture() }

    func particle(depth: CGFloat) -> Particle {
        Particle(radius: 5, alpha: 1, fallSpeed: 40, swayAmplitude: 0, swayFrequency: 0.5,
                 spin: 0.5, flip: 0.25, tint: Self.tint)
    }
}

@MainActor
struct ParticleMotionTests {
    private let size = CGSize(width: 400, height: 300)

    private func flakes(_ scene: SeasonScene) -> [SKSpriteNode] {
        scene.children.compactMap { $0 as? SKSpriteNode }
    }

    @Test func particlesTakeTheirOwnTint() {
        let scene = SeasonScene(size: size, screenOrigin: .zero, season: SpinningSeason())
        scene.setSeason(Snow())
        scene.setSeason(SpinningSeason())
        let tint = SpinningSeason.tint
        #expect(flakes(scene).allSatisfy { node in
            guard let c = node.color.usingColorSpace(.sRGB) else { return false }
            return node.colorBlendFactor == 1 && abs(c.redComponent - tint.redComponent) < 0.01
                && abs(c.greenComponent - tint.greenComponent) < 0.01 && abs(c.blueComponent - tint.blueComponent) < 0.01
        })
    }

    @Test func particlesSpinAndFlipWhileTheyFall() {
        let scene = SeasonScene(size: size, screenOrigin: .zero, season: Snow())
        scene.setSeason(SpinningSeason())
        let before = flakes(scene).map { ($0.zRotation, $0.xScale) }
        scene.step(at: 1)
        scene.step(at: 1.05)
        let after = flakes(scene).map { ($0.zRotation, $0.xScale) }
        #expect(zip(before, after).allSatisfy { $0.0 != $1.0 })
        #expect(zip(before, after).contains { $0.1 != $1.1 })
        #expect(after.allSatisfy { abs($0.1) <= 1 })
    }

    @Test func snowNeitherSpinsNorIsTinted() {
        let scene = SeasonScene(size: size, screenOrigin: .zero, season: Snow())
        scene.setSeason(SpinningSeason())
        scene.setSeason(Snow())
        scene.step(at: 1)
        scene.step(at: 1.05)
        #expect(flakes(scene).allSatisfy { $0.zRotation == 0 && $0.xScale == 1 && $0.colorBlendFactor == 0 })
    }

    @Test func aSeasonCanLeaveNothingWhenItSettles() {
        let scene = SeasonScene(size: size, screenOrigin: .zero, season: Snow())
        scene.setSeason(SpinningSeason())   // senza una view, le particelle nascono qui
        let edge = WindowEdge(id: 1, rect: CGRect(x: 0, y: 0, width: 400, height: 150), visible: [0...400])
        scene.updateWindows([edge], dock: nil, ceiling: 1000)
        var t: TimeInterval = 1
        for _ in 0..<200 { scene.step(at: t); t += 0.05 }
        let pile = scene.children.compactMap { $0 as? SKShapeNode }.first
        #expect(pile?.path?.boundingBoxOfPath.height ?? 0 < 0.1)
    }

    /// Foglie intere, ognuna con la tinta di una foglia d'autunno (SBU-177): mai bianche.
    @Test func leavesKnockedOffAPileFallAsLeafColoredBits() {
        let scene = SeasonScene(size: size, screenOrigin: .zero, season: Snow())
        scene.setSeason(Autumn())
        let edge = WindowEdge(id: 1, rect: CGRect(x: 0, y: 0, width: 400, height: 150), visible: [0...400])
        scene.updateWindows([edge], dock: nil, ceiling: 1000)
        var t: TimeInterval = 1
        for _ in 0..<600 { scene.step(at: t); t += 0.05 }
        scene.updateWindows([], dock: nil, ceiling: 1000)   // la finestra si chiude: il mucchio cade

        let bits = scene.children.compactMap { $0 as? SKSpriteNode }.filter { $0.zPosition == 1.5 }   // i granelli: sotto i mucchi, sopra le foglie
        let palette = AutumnTuning.leaves.compactMap { $0.usingColorSpace(.sRGB) }
        #expect(!bits.isEmpty)
        #expect(bits.allSatisfy { bit in
            guard let c = bit.color.usingColorSpace(.sRGB) else { return false }
            return bit.colorBlendFactor == 1 && palette.contains { leaf in
                abs(c.redComponent - leaf.redComponent) < 0.01 && abs(c.greenComponent - leaf.greenComponent) < 0.01
                    && abs(c.blueComponent - leaf.blueComponent) < 0.01
            }
        })
    }
}
