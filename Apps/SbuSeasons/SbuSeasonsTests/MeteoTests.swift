import AppKit
import SpriteKit
import Testing
@testable import SbuSeasons

/// Il filone meteo di SBU-177: foglie che volano via dai mucchi, petali che restano un po', lucciole che si radunano,
/// stelle che si rompono sui bordi, lampi nella pioggia, arcobaleno, meteo a caso, mucchi più alti, pause e 120 fps.
@MainActor
struct MeteoTests {
    private func run(_ scene: SeasonScene, steps: Int) {
        var t: TimeInterval = 1
        for _ in 0..<steps { scene.step(at: t); t += 0.05 }
    }

    // MARK: - Foglie e petali

    @Test func leavesAndPetalsScatterAsWholePiecesNotDust() {
        #expect(Autumn().pieceSize.lowerBound > Snow().pieceSize.upperBound)
        #expect(Spring().pieceSize.lowerBound > Snow().pieceSize.upperBound)
    }

    @Test func onlyPetalsLingerOnTheWindows() {
        #expect(Spring().linger != nil)
        #expect(Snow().linger == nil)
        #expect(Autumn().linger == nil)
    }

    @Test func aRestingPetalFadesAndGoesAwayAfterItsTime() {
        let pile = Pile(minX: 0, width: 100, baseY: 200, cornerRadius: 0, maxHeight: 16, color: .white)
        pile.rest(SKSpriteNode(color: .white, size: CGSize(width: 6, height: 6)), atX: 50, life: 2)
        #expect(pile.restingCount == 1)
        pile.age(by: 1.5)
        #expect(pile.restingCount == 1)
        pile.age(by: 1)
        #expect(pile.restingCount == 0)
    }

    @Test func theCursorBrushesRestingPetalsAway() {
        let pile = Pile(minX: 0, width: 100, baseY: 200, cornerRadius: 0, maxHeight: 16, color: .white)
        pile.rest(SKSpriteNode(color: .white, size: CGSize(width: 6, height: 6)), atX: 20, life: 30)
        pile.rest(SKSpriteNode(color: .white, size: CGSize(width: 6, height: 6)), atX: 80, life: 30)
        let brushed = pile.scoop(at: CGPoint(x: 22, y: 201), radius: 14)
        #expect(brushed.count == 1)
        #expect(pile.restingCount == 1)
    }

    @Test func restingPetalsFollowAWindowMovedSlowly() {
        let old = Pile(minX: 0, width: 100, baseY: 200, cornerRadius: 0, maxHeight: 16, color: .white)
        old.rest(SKSpriteNode(color: .white, size: CGSize(width: 6, height: 6)), atX: 50, life: 30)
        let moved = Pile(minX: 10, width: 100, baseY: 220, cornerRadius: 0, maxHeight: 16, color: .white)
        moved.carry(old)
        #expect(moved.restingCount == 1)
        #expect(moved.node.children.first?.position.x == 60)
    }

    @Test func clearingTheWindowsTakesThePetalsToo() {
        let pile = Pile(minX: 0, width: 100, baseY: 200, cornerRadius: 0, maxHeight: 16, color: .white)
        pile.rest(SKSpriteNode(color: .white, size: CGSize(width: 6, height: 6)), atX: 50, life: 30)
        pile.clear()
        #expect(pile.restingCount == 0)
        pile.rest(SKSpriteNode(color: .white, size: CGSize(width: 6, height: 6)), atX: 50, life: 30)
        #expect(pile.releaseAll().count >= 1)
        #expect(pile.restingCount == 0)
    }

    // MARK: - Lucciole

    @Test func firefliesGatherOnlyAfterTheCursorRestsAndSlowerWithReduceMotion() {
        #expect(Fireflies().gathers)
        #expect(!Snow().gathers)
        #expect(Tuning.gatherPull(still: 0, calm: false) == 0)
        #expect(Tuning.gatherPull(still: Tuning.gatherDelay - 0.1, calm: false) == 0)
        let full = Tuning.gatherPull(still: Tuning.gatherDelay + 60, calm: false)
        #expect(full > 0)
        #expect(Tuning.gatherPull(still: Tuning.gatherDelay + 60, calm: true) < full)
    }

    @Test func theCursorCountsAsStillUntilItMovesAFewPoints() {
        var still = Stillness()
        still.update(CGPoint(x: 100, y: 100), dt: 1)
        still.update(CGPoint(x: 101, y: 100), dt: 1)
        #expect(still.seconds == 2)
        still.update(CGPoint(x: 140, y: 100), dt: 1)
        #expect(still.seconds == 0)
    }

    // MARK: - Stelle cadenti

    @Test func onlyShootingStarsShatter() {
        #expect(Meteors().shatters)
        #expect(!Snow().shatters)
    }

    @Test func aStarHitsAWindowEdgeOnlyWhenItCrossesItInsideTheOpenSpan() {
        let edge = Ledge(y: 300, span: 100...400)
        #expect(ledgeHit(from: CGPoint(x: 200, y: 305), to: CGPoint(x: 210, y: 295), ledges: [edge]) == edge)
        #expect(ledgeHit(from: CGPoint(x: 50, y: 305), to: CGPoint(x: 60, y: 295), ledges: [edge]) == nil)
        #expect(ledgeHit(from: CGPoint(x: 200, y: 295), to: CGPoint(x: 210, y: 285), ledges: [edge]) == nil)
    }

    @Test func sparksFlyAndThenAreGone() {
        let sparks = Sparks()
        sparks.burst(at: CGPoint(x: 100, y: 100), color: .white, calm: false)
        #expect(sparks.count == Tuning.sparksPerBurst)
        for _ in 0..<40 { sparks.step(dt: 0.05) }
        #expect(sparks.count == 0)
        sparks.burst(at: CGPoint(x: 100, y: 100), color: .white, calm: true)
        #expect(sparks.count < Tuning.sparksPerBurst)
    }

    // MARK: - Pioggia e arcobaleno

    @Test func rainHasAFarLightningEveryNowAndThenWeakerThanTheStorm() throws {
        let rain = try #require(Rain().lightning)
        let storm = try #require(Storm().lightning)
        #expect(rain.strength < storm.strength)
        #expect(rain.every.lowerBound > storm.every.lowerBound)
    }

    @Test(arguments: [
        (from: "rain", to: "snow", rainbow: true),
        (from: "storm", to: "clear", rainbow: true),
        (from: "rain", to: "storm", rainbow: false),
        (from: "snow", to: "clear", rainbow: false),
    ])
    func aRainbowFollowsTheRainWhenTheEffectChanges(from: String, to: String, rainbow: Bool) {
        #expect(Rainbow.follows(from: from, to: to) == rainbow)
    }

    @Test func theRainbowFadesInStaysAndFadesOut() {
        #expect(Rainbow.alpha(at: 0, calm: false) == 0)
        #expect(Rainbow.alpha(at: Tuning.rainbowFadeIn + 1, calm: false) == 1)
        #expect(Rainbow.alpha(at: Tuning.rainbowLife + 1, calm: false) == 0)
        // Riduci movimento: c'è o non c'è, senza dissolvenza.
        #expect(Rainbow.alpha(at: 0.01, calm: true) == 1)
    }

    @Test func aSceneShowsTheRainbowAndThenTakesItAway() {
        let scene = SeasonScene(size: CGSize(width: 400, height: 300), screenOrigin: .zero, season: Clear())
        scene.showRainbow()
        run(scene, steps: 20)
        #expect(scene.rainbow.isShowing)
        run(scene, steps: Int(Tuning.rainbowLife / 0.05) + 10)
        #expect(!scene.rainbow.isShowing)
    }

    // MARK: - Meteo a caso

    @Test(arguments: 1...12)
    func randomWeatherKeepsToTheSeasonOfTheYear(month: Int) {
        let pool = WeatherShuffle.pool(month: month)
        #expect(pool.count >= 4)
        #expect(!pool.contains(Clear.id))
        let year: [ClosedRange<Int>: String] = [12...12: Snow.id, 1...2: Snow.id, 3...5: Spring.id,
                                                6...8: Summer.id, 9...11: Autumn.id]
        let own = year.first { $0.key.contains(month) }?.value
        #expect(pool.contains(own ?? ""))
        for id in pool { #expect(Seasons.named(id).id == id) }   // ogni voce è una stagione vera
    }

    @Test func randomWeatherNeverPicksTheEffectAlreadyOn() {
        for _ in 0..<50 {
            #expect(WeatherShuffle.next(after: Snow.id, month: 1) != Snow.id)
        }
    }

    @Test func theWeatherClockWaitsItsIntervalAndForgetsWhenTurnedOff() {
        var clock = WeatherClock()
        let ticks = [
            clock.tick(now: 0, enabled: true),
            clock.tick(now: Tuning.weatherShuffle.lowerBound - 1, enabled: true),
            clock.tick(now: Tuning.weatherShuffle.upperBound + 1, enabled: true),
            clock.tick(now: Tuning.weatherShuffle.upperBound + 2, enabled: true),
            clock.tick(now: 10_000, enabled: false),
            clock.tick(now: 10_001, enabled: true),   // riacceso: riparte l'attesa
        ]
        #expect(ticks == [false, false, true, false, false, false])
    }

    // MARK: - Neve più alta

    @Test func tallSnowRaisesThePilesOnTheEdges() {
        var settings = SnowSettings()
        let normal = settings.pileHeight
        settings.tallSnow = true
        #expect(settings.pileHeight == normal * Tuning.tallSnowFactor)
        #expect(SnowSettings().tallSnow == false)
    }

    // MARK: - Pausa automatica e 120 fps

    @Test func aFullScreenWindowCoversTheScreenAMaximisedOneDoesNot() {
        let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)
        #expect(coversScreen([CGRect(x: 0, y: 0, width: 1440, height: 900)], screen: screen))
        #expect(!coversScreen([CGRect(x: 0, y: 0, width: 1440, height: 875)], screen: screen))
        #expect(!coversScreen([CGRect(x: 1440, y: 0, width: 1440, height: 900)], screen: screen))
    }

    @Test(arguments: [
        (onBattery: false, reduceMotion: false, highRate: true, maxFPS: 120, fps: 120),
        (onBattery: false, reduceMotion: false, highRate: false, maxFPS: 120, fps: 60),
        (onBattery: false, reduceMotion: false, highRate: true, maxFPS: 60, fps: 60),
        (onBattery: true, reduceMotion: false, highRate: true, maxFPS: 120, fps: 30),
        (onBattery: false, reduceMotion: true, highRate: true, maxFPS: 120, fps: 30),
    ])
    func promotionRunsAt120OnlyWhenAskedOnPowerAndWithoutReduceMotion(
        onBattery: Bool, reduceMotion: Bool, highRate: Bool, maxFPS: Int, fps: Int
    ) {
        #expect(Tuning.framesPerSecond(onBattery: onBattery, reduceMotion: reduceMotion, highRate: highRate,
                                       maxFPS: maxFPS) == fps)
        #expect(SnowSettings().highFrameRate == false)
    }

    @Test func randomWeatherStartsOffTheRainbowOn() {
        let settings = SnowSettings()
        #expect(!settings.randomWeather)
        #expect(settings.rainbow)   // l'arcobaleno è gentile: acceso di base, si spegne nelle Impostazioni
    }
}

/// Le voci nuove delle Impostazioni → Meteo hanno l'inglese nel bundle.
@Test(arguments: [
    ("Meteo", "Weather"),
    ("Meteo a caso", "Random Weather"),
    ("Arcobaleno dopo la pioggia", "Rainbow After the Rain"),
    ("Mucchi più alti", "Taller Piles"),
    ("120 fps sugli schermi ProMotion", "120 fps on ProMotion Displays"),
])
func theWeatherSettingsAreTranslated(_ italian: String, _ english: String) throws {
    let path = try #require(Bundle.main.path(forResource: "en", ofType: "lproj"))
    let bundle = try #require(Bundle(path: path))
    #expect(bundle.localizedString(forKey: italian, value: nil, table: nil) == english)
}

/// Le funzioni nella scena vera, col cursore finto (`pointerLocation`).
@MainActor
struct MeteoSceneTests {
    private let size = CGSize(width: 800, height: 600)

    private func run(_ scene: SeasonScene, seconds: Double, from start: TimeInterval = 1) -> TimeInterval {
        var t = start
        for _ in 0..<Int(seconds / 0.05) { scene.step(at: t); t += 0.05 }
        return t
    }

    private func lights(_ scene: SeasonScene) -> [CGPoint] {
        scene.children.compactMap { $0 as? SKSpriteNode }.filter { $0.zPosition <= 1 }.map(\.position)
    }

    private func near(_ points: [CGPoint], _ target: CGPoint) -> Int {
        points.filter { hypot($0.x - target.x, $0.y - target.y) < Tuning.gatherRing.upperBound + 20 }.count
    }

    @Test func firefliesGatherAroundAStillCursorAndScatterWhenItMoves() {
        let scene = SeasonScene(size: size, screenOrigin: .zero, season: Clear())
        var cursor = CGPoint(x: 400, y: 300)
        scene.pointerLocation = { cursor }
        scene.setSeason(Fireflies())
        let before = near(lights(scene), cursor)
        let t = run(scene, seconds: Double(Tuning.gatherDelay + Tuning.gatherRamp) + 6)
        let gathered = near(lights(scene), cursor)
        #expect(gathered > before)
        #expect(gathered >= lights(scene).count / 2)

        let still = cursor
        cursor = CGPoint(x: 100, y: 100)   // il cursore riparte, lontano
        _ = run(scene, seconds: 4, from: t)
        #expect(near(lights(scene), still) < gathered)
    }

    @Test func aShootingStarBreaksIntoSparksOnAWindowEdge() {
        let scene = SeasonScene(size: size, screenOrigin: .zero, season: Clear())
        scene.pointerLocation = { CGPoint(x: -1000, y: -1000) }
        scene.setSeason(Meteors())
        // Una finestra larga quanto lo schermo, a metà altezza: ogni stella che scende la attraversa.
        let edge = WindowEdge(id: 1, rect: CGRect(x: 0, y: 0, width: 800, height: 300), visible: [0...800])
        scene.updateWindows([edge], dock: nil, ceiling: 1000)
        var t: TimeInterval = 1
        var burst = false
        for _ in 0..<2400 where !burst {   // le stelle aspettano fino a 45 s prima di passare
            scene.step(at: t)
            t += 0.05
            burst = scene.sparks.count > 0
        }
        #expect(burst)
    }
}
