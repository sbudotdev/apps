import CoreGraphics
import SpriteKit
import Testing
@testable import SbuSeasons

/// La letterina a Babbo Natale (SBU-178): la busta sale, la slitta passa e se la porta via. Il testo non arriva
/// nemmeno alla scena: `mailLetter` non lo riceve.
@MainActor
struct LetterTests {
    private func scene(reduceMotion: Bool = false) -> SeasonScene {
        let scene = SeasonScene(size: CGSize(width: 1000, height: 800), screenOrigin: .zero, season: Snow())
        scene.reduceMotion = reduceMotion
        scene.updateWindows([], dock: nil, ceiling: 780)
        return scene
    }

    /// I passi della scena e le azioni SpriteKit (la busta che sale) insieme, come nell'app.
    private func run(_ scene: SeasonScene, seconds: TimeInterval) {
        for i in 0...Int(seconds * 60) {
            let t = TimeInterval(i) / 60
            scene.step(at: t)
            scene.letter?.removeAllActions()   // la salita la fa SpriteKit: qui la saltiamo
            if let letter = scene.letter { letter.position.y = 780 * Tuning.santaAltitude - 6 }
        }
    }

    @Test func theSleighTakesTheLetterAway() throws {
        let scene = scene()
        #expect(scene.mailLetter(from: CGPoint(x: 500, y: 300)))
        let envelope = try #require(scene.letter)
        run(scene, seconds: 4)
        let santa = try #require(scene.santa, "Babbo Natale è venuto a prenderla")
        #expect(scene.letter == nil)
        #expect(envelope.parent === santa.node, "è nel sacco")
        run(scene, seconds: 10)
        #expect(scene.santa == nil)
        #expect(envelope.scene == nil, "è volata via con la slitta")
    }

    @Test func withReduceMotionTheLetterJustFadesAway() {
        let scene = scene(reduceMotion: true)
        #expect(scene.mailLetter(from: CGPoint(x: 500, y: 300)))
        #expect(scene.letter == nil)
        #expect(scene.santa == nil)
    }

    @Test func noLetterWhileTheToysArePausedOrOutsideWinter() {
        let paused = scene()
        paused.toysPaused = true
        #expect(!paused.mailLetter(from: CGPoint(x: 500, y: 300)))
        let summer = SeasonScene(size: CGSize(width: 1000, height: 800), screenOrigin: .zero, season: Summer())
        #expect(!summer.mailLetter(from: CGPoint(x: 500, y: 300)))
    }

    @Test func pausingTheToysTakesTheLetterAway() {
        let scene = scene()
        scene.mailLetter(from: CGPoint(x: 500, y: 300))
        scene.toysPaused = true
        #expect(scene.letter == nil)
    }
}
