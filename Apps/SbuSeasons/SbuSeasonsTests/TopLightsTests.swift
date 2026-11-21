import CoreGraphics
import Foundation
import Testing
@testable import SbuSeasons

/// «Luci in alto» (SBU-229): il filo di luci sotto la barra dei menu. Scelte salvate, lampadine e animazioni.
struct TopLightsTests {
    @Test func choicesAreSavedAndReadBack() throws {
        var values = SnowSettings()
        values.topLights = true
        values.topLightsPalette = .single
        values.topLightsColor = .blue
        values.topLightsShape = .star
        values.topLightsAnimation = .wave
        #expect(SnowSettings(saved: try JSONEncoder().encode(values)) == values)
    }

    @Test func offByDefaultAndOlderSavesKeepTheirValues() {
        let old = SnowSettings(saved: Data(#"{"wind": 30}"#.utf8))
        #expect(!old.topLights)
        #expect(old.topLightsPalette == .multicolor)
        #expect(old.topLightsShape == .round)
        #expect(old.topLightsAnimation == .chase)
        #expect(old.wind == 30)
    }

    /// Una scelta che questa versione non conosce torna al predefinito, le altre restano.
    @Test func unknownChoiceFallsBackOnlyForItself() {
        let read = SnowSettings(saved: Data(#"{"topLights": true, "topLightsShape": "heart", "topLightsAnimation": "wave"}"#.utf8))
        #expect(read.topLights)
        #expect(read.topLightsShape == .round)
        #expect(read.topLightsAnimation == .wave)
    }

    @Test(arguments: [1024.0, 1440, 1920, 2560, 3440, 5120])
    func bulbsFollowTheScreenWidthAtRegularSteps(width: Double) throws {
        let xs = TopLights.bulbXs(width: width)
        #expect(xs.count == Int(width / Tuning.topLightsBulbGap))
        let steps = zip(xs, xs.dropFirst()).map { $1 - $0 }
        let step = try #require(steps.first)
        #expect(steps.allSatisfy { abs($0 - step) < 0.001 })
        #expect(step >= Tuning.topLightsBulbGap && step < Tuning.topLightsBulbGap * 1.1)
        // Dall'orlo sinistro a quello destro, mezzo passo di margine per parte.
        #expect(abs(xs[0] - step / 2) < 0.001 && abs(width - xs[xs.count - 1] - step / 2) < 0.001)
    }

    @Test func widerScreenHasMoreBulbs() {
        #expect(TopLights.bulbXs(width: 2560).count > TopLights.bulbXs(width: 1440).count)
        #expect(TopLights.bulbXs(width: 10).count == 1)
    }

    /// Il filo è teso ai ganci e pende tra uno e l'altro, al massimo `topLightsSag` a metà.
    @Test func wireSagsBetweenHooks() throws {
        let width = 1920.0
        let hooks = TopLights.hookXs(width: width)
        #expect(hooks.first == 0 && hooks.last == width)
        #expect(hooks.count >= 3)
        for (a, b) in zip(hooks, hooks.dropFirst()) {
            #expect(TopLights.sag(at: a, width: width) < 0.001)
            #expect(abs(TopLights.sag(at: (a + b) / 2, width: width) - Tuning.topLightsSag) < 0.001)
            #expect(TopLights.sag(at: a + (b - a) / 4, width: width) < Tuning.topLightsSag)
        }
    }

    @Test(arguments: TopLights.Animation.allCases)
    func reduceMotionHoldsTheLightsStill(_ chosen: TopLights.Animation) {
        let animation = TopLights.animation(chosen, reduceMotion: true)
        #expect(animation == .steady)
        for time in stride(from: 0.0, through: 10, by: 0.37) {
            for index in 0..<12 { #expect(TopLights.glow(index: index, time: time, animation: animation) == 1) }
        }
    }

    @Test(arguments: [TopLights.Animation.chase, .slowBlink, .wave])
    func animationsChangeOverTime(_ animation: TopLights.Animation) {
        #expect(TopLights.animation(animation, reduceMotion: false) == animation)
        let glows = stride(from: 0.0, through: 6, by: 0.25).map { TopLights.glow(index: 3, time: $0, animation: animation) }
        #expect(Set(glows).count > 1)
        #expect(glows.allSatisfy { $0 >= Tuning.topLightsDim - 0.001 && $0 <= 1.001 })
    }

    /// A turno: in ogni momento è accesa una lampadina ogni `topLightsChaseGroup`, e il turno passa alla vicina.
    @Test func chaseLightsOneInAGroupAndMoves() {
        let group = Tuning.topLightsChaseGroup
        let lit = (0..<group * 4).filter { TopLights.glow(index: $0, time: 0, animation: .chase) == 1 }
        #expect(lit.count == 4)
        let later = (0..<group * 4).filter { TopLights.glow(index: $0, time: Tuning.topLightsChaseStep, animation: .chase) == 1 }
        #expect(later == lit.map { $0 + 1 })
    }

    @Test func onlyAnimatedLightsNeedTheClock() {
        #expect(!TopLights.Animation.steady.moves)
        #expect(TopLights.Animation.allCases.filter(\.moves) == [.chase, .slowBlink, .wave])
    }
}
