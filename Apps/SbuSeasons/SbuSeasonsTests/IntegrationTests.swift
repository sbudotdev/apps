import CoreGraphics
import Foundation
import Testing
@testable import SbuSeasons

/// Dove i tre filoni della 2.1 si toccano (SBU-193): la scelta degli schermi e la pausa automatica del meteo (SBU-177)
/// con i visitatori dei giochi (SBU-178) e Babbo Natale. Su uno schermo fermo la scena non gira: chi ci entrasse
/// resterebbe lì, e il visitatore non ripasserebbe più.
@MainActor
struct IntegrationTests {
    private let size = CGSize(width: 1000, height: 800)

    private func scene(origin: CGPoint = .zero) -> SeasonScene {
        let scene = SeasonScene(size: size, screenOrigin: origin, season: Snow())
        scene.updateWindows([], dock: nil, ceiling: 780)
        return scene
    }

    @Test func theTrainSkipsAScreenWhereTheEffectIsStopped() {
        let left = scene()
        let right = scene(origin: CGPoint(x: 1000, y: 0))
        left.effectRuns = false
        let visitors = Visitors(random: { 0.9 })   // verso destra: partirebbe da sinistra
        visitors.scenes = [left, right]
        #expect(visitors.send(.train))
        #expect(left.train == nil)
        #expect(right.train != nil)
    }

    @Test func nobodyComesWhenEveryScreenIsStopped() {
        let only = scene()
        only.effectRuns = false
        let visitors = Visitors(random: { 0.9 })
        visitors.scenes = [only]
        #expect(!visitors.send(.train))
        #expect(only.train == nil)
    }

    @Test func aTripStuckOnAStoppedScreenDoesNotBlockTheNextOne() {
        let left = scene()
        let right = scene(origin: CGPoint(x: 1000, y: 0))
        let visitors = Visitors(random: { 0.9 })
        visitors.scenes = [left, right]
        #expect(visitors.send(.train))
        #expect(left.train != nil)
        left.effectRuns = false   // un'app a schermo intero copre lo schermo a sinistra
        #expect(visitors.send(.train))
        #expect(right.train != nil)
    }

    @Test func santaSkipsAScreenWhereTheEffectIsStopped() {
        let left = scene()
        let right = scene(origin: CGPoint(x: 1000, y: 0))
        left.effectRuns = false
        let passages = Passages(random: { 0.75 })   // verso destra
        passages.scenes = [left, right]
        #expect(passages.send(at: 0))
        #expect(left.santa == nil)
        #expect(right.santa != nil)
    }

    @Test func aFlightStuckOnAStoppedScreenEndsAtTheNextTick() {
        let left = scene()
        let right = scene(origin: CGPoint(x: 1000, y: 0))
        let passages = Passages(random: { 0.75 })
        passages.scenes = [left, right]
        #expect(passages.send(at: 0))
        #expect(left.santa != nil)
        left.effectRuns = false
        passages.tick(at: 1)
        #expect(!passages.isFlying)
    }
}
