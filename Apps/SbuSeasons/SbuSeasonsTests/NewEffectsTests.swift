import AppKit
import SpriteKit
import Testing
@testable import SbuSeasons

/// Gli effetti della 2.0 (SBU-51): lucciole, stelle cadenti, sereno e l'intensità continua.
@MainActor
struct NewEffectsTests {
    private let size = CGSize(width: 400, height: 300)

    private func particles(_ scene: SeasonScene) -> [SKSpriteNode] {
        scene.children.compactMap { $0 as? SKSpriteNode }
    }

    private func run(_ scene: SeasonScene, steps: Int, from start: TimeInterval = 1) {
        var t = start
        for _ in 0..<steps { scene.step(at: t); t += 0.05 }
    }

    /// Una finestra larga quanto lo schermo, alta metà: tutto ciò che si posa, si posa lì.
    private func pileHeight(after season: any Season) -> CGFloat {
        let scene = SeasonScene(size: size, screenOrigin: .zero, season: Snow())
        scene.setSeason(season)
        let edge = WindowEdge(id: 1, rect: CGRect(x: 0, y: 0, width: 400, height: 150), visible: [0...400])
        scene.updateWindows([edge], dock: nil, ceiling: 1000)
        run(scene, steps: 300)
        let pile = scene.children.compactMap { $0 as? SKShapeNode }.first
        return pile?.path?.boundingBoxOfPath.height ?? 0
    }

    @Test func theNewEffectsAreInTheSeasonMenuAfterTheOldOnes() {
        let ids = Seasons.all.map(\.id)
        #expect(Array(ids.prefix(4)) == ["snow", "spring", "summer", "autumn"])
        #expect(Array(ids.dropFirst(4)) == ["rain", "storm", "mist", "clouds", "fireflies", "meteors", "clear"])
        #expect(Seasons.named("fireflies") is Fireflies)
        #expect(Seasons.named("meteors") is Meteors)
        #expect(Seasons.named("clear") is Clear)
        #expect(Set(Seasons.all.map(\.symbol)).count == Seasons.all.count)   // ogni stagione la sua icona
    }

    // MARK: - Sereno

    @Test func clearSkiesHaveNothingFalling() {
        let scene = SeasonScene(size: size, screenOrigin: .zero, season: Snow())
        scene.setSeason(Clear())
        run(scene, steps: 20)
        #expect(scene.flakeCount == 0)
        #expect(particles(scene).isEmpty)
    }

    /// Chi passa a una stagione dove non si posa niente non resta con la neve di prima ricolorata.
    @Test func goingClearMeltsWhatHadSettled() {
        let scene = SeasonScene(size: size, screenOrigin: .zero, season: Clear())
        scene.setSeason(Snow())   // senza una view, le particelle nascono qui
        let edge = WindowEdge(id: 1, rect: CGRect(x: 0, y: 0, width: 400, height: 150), visible: [0...400])
        scene.updateWindows([edge], dock: nil, ceiling: 1000)
        run(scene, steps: 300)
        let pile = { scene.children.compactMap { $0 as? SKShapeNode }.first?.path?.boundingBoxOfPath.height ?? 0 }
        #expect(pile() > 1)
        scene.setSeason(Clear())
        run(scene, steps: 3, from: 100)
        #expect(pile() < 0.1)
    }

    // MARK: - Lucciole

    @Test func firefliesNeverSettle() {
        #expect(pileHeight(after: Fireflies()) < 0.1)
    }

    /// Vagano: dopo un po' sono quasi tutte ancora sullo schermo, e si sono mosse.
    @Test func firefliesWanderAroundTheScreen() {
        let scene = SeasonScene(size: size, screenOrigin: .zero, season: Fireflies())
        scene.setSeason(Snow())
        scene.setSeason(Fireflies())
        let before = particles(scene).map(\.position)
        run(scene, steps: 100)
        let after = particles(scene).map(\.position)
        let screen = CGRect(origin: .zero, size: size).insetBy(dx: -40, dy: -40)
        #expect(after.filter { screen.contains($0) }.count >= after.count * 9 / 10)
        #expect(zip(before, after).allSatisfy { hypot($0.x - $1.x, $0.y - $1.y) > 1 })
    }

    /// Si accendono e si spengono piano, non tutte insieme.
    @Test func firefliesGlowOnAndOff() {
        let scene = SeasonScene(size: size, screenOrigin: .zero, season: Fireflies())
        scene.setSeason(Snow())
        scene.setSeason(Fireflies())
        var alphas: [[CGFloat]] = []
        var t: TimeInterval = 1
        for _ in 0..<60 { scene.step(at: t); t += 0.05; alphas.append(particles(scene).map(\.alpha)) }
        let first = particles(scene).indices.map { i in alphas.map { $0[i] } }
        #expect(first.allSatisfy { ($0.max()! - $0.min()!) > 0.2 })
        #expect(Set(alphas.last!.map { ($0 * 100).rounded() }).count > 1)
    }

    // MARK: - Stelle cadenti

    /// Ogni tanto: poche, e all'inizio nessuna è già in cielo.
    @Test func shootingStarsAreRareAndStartOffScreen() {
        let snow = SeasonScene(size: size, screenOrigin: .zero, season: Clear())
        snow.setSeason(Snow())
        let scene = SeasonScene(size: size, screenOrigin: .zero, season: Snow())
        scene.setSeason(Meteors())
        #expect(scene.flakeCount >= 1)
        #expect(scene.flakeCount * 10 <= snow.flakeCount)
        #expect(particles(scene).allSatisfy { $0.position.y > size.height })
    }

    /// Una scia attraversa il cielo in diagonale, veloce, orientata come si muove.
    @Test func aShootingStarCrossesTheSkyDiagonally() throws {
        let scene = SeasonScene(size: size, screenOrigin: .zero, season: Snow())
        scene.setSeason(Meteors())
        let star = try #require(particles(scene).first)
        // Aspetta che arrivi in cielo: sopra lo schermo scende dritta.
        var t: TimeInterval = 1
        while star.position.y > size.height - 20 { scene.step(at: t); t += 0.05 }
        let start = star.position
        scene.step(at: t)
        scene.step(at: t + 0.05)
        let dx = star.position.x - start.x, dy = star.position.y - start.y
        #expect(dy < -10)
        #expect(abs(dx) > 10)
        // La punta della texture (a destra) guarda dove va.
        let heading = atan2(dy, dx)
        #expect(abs(remainder(star.zRotation - heading, 2 * .pi)) < 0.3)
        #expect(star.size.width > star.size.height * 4)
    }

    /// Mentre aspetta sopra lo schermo non va di lato: ogni giro finisce con la stella che attraversa il cielo
    /// (uscita di lato o dal fondo), mai uscita di lato quando era ancora sopra, invisibile.
    @Test func everyShootingStarShowsUpAfterItsWait() throws {
        let scene = SeasonScene(size: size, screenOrigin: .zero, season: Snow())
        scene.setSeason(Meteors())
        let star = try #require(particles(scene).first)
        let sky = CGRect(origin: .zero, size: size)
        var seen = false, laps = 0, t: TimeInterval = 1
        var lastY = star.position.y
        var lastPos = star.position
        for _ in 0..<12_000 {
            scene.step(at: t); t += 0.05
            if sky.contains(star.position) { seen = true }
            if star.position.y > lastY + 50 {   // è rinata in cima: il giro prima doveva vedersi
                #expect(seen, "giro \(laps): uscita in \(lastPos) senza farsi vedere")
                seen = false
                laps += 1
            }
            lastY = star.position.y
            lastPos = star.position
        }
        #expect(laps >= 3)
    }

    @Test func shootingStarsNeverSettle() {
        #expect(pileHeight(after: Meteors()) < 0.1)
    }

    // MARK: - Intensità continua

    /// Muovere il cursore dell'intensità aggiunge o toglie particelle: quelle che ci sono restano dove sono.
    @Test func changingIntensityKeepsTheParticlesAlreadyFalling() {
        let saved = Settings.shared.values.flakeCount
        defer { Settings.shared.values.flakeCount = saved }
        Settings.shared.values.flakeCount = 200
        let scene = SeasonScene(size: size, screenOrigin: .zero, season: Snow())
        scene.setSeason(Spring())
        scene.step(at: 1)
        let before = Set(particles(scene).map(ObjectIdentifier.init))

        Settings.shared.values.flakeCount = 400
        scene.step(at: 1.02)
        let more = Set(particles(scene).map(ObjectIdentifier.init))
        #expect(more.count > before.count)
        #expect(before.isSubset(of: more))

        Settings.shared.values.flakeCount = 100
        scene.step(at: 1.04)
        let fewer = Set(particles(scene).map(ObjectIdentifier.init))
        #expect(fewer.count < before.count)
        #expect(fewer.isSubset(of: more))
    }

    @Test func theIntensitySliderCoversTheThreePresets() {
        for density in Density.allCases {
            #expect(Density.range.contains(density.flakesPerReferenceScreen))
        }
    }
}
