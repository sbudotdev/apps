import AppKit
import SpriteKit
import Testing
@testable import SbuSeasons

/// Il secondo giro del filone meteo (SBU-185): vento con direzione e variabile, pausa con i videogiochi,
/// risparmio energetico, scelta degli schermi, finestre pulite, segui la stagione, schizzi e fulmine sul Dock.
@MainActor
struct MeteoSecondRoundTests {

    // MARK: - Vento

    @Test(arguments: [30.0, -30.0])
    func aSteadyWindKeepsItsSideAndOnlyGusts(base: Double) {
        for t in stride(from: 0.0, through: 900, by: 3) {
            let w = Wind.speed(at: CGFloat(t), base: CGFloat(base), variable: false)
            #expect(w.sign == CGFloat(base).sign)
            #expect(abs(w) <= abs(CGFloat(base)) + 0.001)
            #expect(abs(w) >= abs(CGFloat(base)) * Tuning.windGustDip - 0.001)
        }
        #expect(Wind.speed(at: 10, base: 0, variable: false) == 0)
    }

    @Test func aVariableWindRisesCalmsAndTurnsEveryFewMinutes() {
        let samples = stride(from: 0.0, through: 900, by: 1).map { Wind.speed(at: CGFloat($0), base: 40, variable: true) }
        #expect(samples.contains { $0 > 20 })     // si alza verso destra…
        #expect(samples.contains { $0 < -20 })    // …e gira verso sinistra
        #expect(samples.contains { abs($0) < 3 }) // in mezzo si calma
        #expect(samples.allSatisfy { abs($0) <= 40.001 })
        // Anche con il cursore a zero il vento variabile soffia un po'.
        #expect(stride(from: 0.0, through: 900, by: 1).contains { abs(Wind.speed(at: CGFloat($0), base: 0, variable: true)) > 10 })
    }

    @Test func oldSavesKeepTheirWindAndTheVariableWindStartsOff() throws {
        let saved = try JSONSerialization.data(withJSONObject: ["wind": 25.0])
        let settings = SnowSettings(saved: saved)
        #expect(settings.wind == 25)
        #expect(!settings.variableWind)
        #expect(SnowSettings.windRange.contains(-80) && SnowSettings.windRange.contains(80))
    }

    // MARK: - Pausa quando giochi a un videogioco

    @Test(arguments: [
        (category: "public.app-category.games", path: "/Applications/Chess.app", game: true),
        (category: "public.app-category.action-games", path: "/Applications/Doom.app", game: true),
        (category: "public.app-category.strategy-games", path: "/Applications/X.app", game: true),
        (category: nil, path: "/Users/a/Library/Application Support/Steam/steamapps/common/Hades/Hades.app", game: true),
        (category: "public.app-category.productivity", path: "/Applications/Pages.app", game: false),
        (category: "public.app-category.entertainment", path: "/Applications/Sbu Seasons.app", game: false),
        (category: nil, path: "/Applications/Steam.app", game: false),
    ] as [(category: String?, path: String, game: Bool)])
    func aGameIsRecognisedFromItsCategoryOrFromSteam(category: String?, path: String, game: Bool) {
        #expect(VideoGame.isGame(category: category, path: path) == game)
    }

    @Test func theVideoGamePauseStartsOn() {
        #expect(SnowSettings().pauseForVideoGames)
    }

    // MARK: - Quando gira l'effetto

    @Test func theEffectRunsOnlyWhenNothingStopsIt() {
        let free = EffectGate(snowing: true, displaysAsleep: false, screenCovered: false, gameInFront: false,
                              screenOff: false, stopOnBattery: false, onBattery: true)
        #expect(free.runs)
        #expect(!EffectGate(snowing: false, displaysAsleep: false, screenCovered: false, gameInFront: false,
                            screenOff: false, stopOnBattery: false, onBattery: false).runs)
        var gate = free
        gate.gameInFront = true
        #expect(!gate.runs)
        gate = free
        gate.screenOff = true
        #expect(!gate.runs)
        gate = free
        gate.stopOnBattery = true
        #expect(!gate.runs)            // a batteria, con «Ferma a batteria»
        gate.onBattery = false
        #expect(gate.runs)             // a corrente riparte
    }

    // MARK: - Energia

    @Test(arguments: [
        (lowPower: false, thermal: ProcessInfo.ThermalState.nominal, share: 1.0),
        (lowPower: false, thermal: .fair, share: 1.0),
        (lowPower: true, thermal: .nominal, share: 0.5),
        (lowPower: false, thermal: .serious, share: 0.5),
        (lowPower: false, thermal: .critical, share: 0.5),
    ])
    func lowPowerOrAHotMacHalvesTheEffect(lowPower: Bool, thermal: ProcessInfo.ThermalState, share: Double) {
        #expect(Tuning.energyShare(lowPower: lowPower, thermal: thermal) == CGFloat(share))
    }

    @Test func savingEnergyHalvesTheFlakes() {
        let scene = SeasonScene(size: CGSize(width: 1440, height: 900), screenOrigin: .zero, season: Snow())
        scene.didMove(to: SKView())
        let full = scene.flakeCount
        scene.energyShare = 0.5
        #expect(abs(scene.flakeCount - full / 2) <= 1)
        scene.energyShare = 1
        #expect(scene.flakeCount == full)
    }

    @Test func stopOnBatteryStartsOff() {
        #expect(!SnowSettings().stopOnBattery)
    }

    // MARK: - Scelta degli schermi

    @Test func eachScreenCanBeTurnedOffOnItsOwn() {
        var settings = SnowSettings()
        #expect(settings.showsEffect(onScreen: "Studio Display"))
        settings.setEffect(false, onScreen: "Studio Display")
        #expect(!settings.showsEffect(onScreen: "Studio Display"))
        #expect(settings.showsEffect(onScreen: "Built-in Retina Display"))
        settings.setEffect(false, onScreen: "Studio Display")   // due volte: una sola voce
        #expect(settings.screensOff == ["Studio Display"])
        settings.setEffect(true, onScreen: "Studio Display")
        #expect(settings.showsEffect(onScreen: "Studio Display"))
        #expect(settings.screensOff.isEmpty)
    }

    // MARK: - Finestre pulite

    @Test func cleanWindowsMeltsThePileSlowlyDownToAThinLayer() {
        let pile = Pile(minX: 0, width: 100, baseY: 200, cornerRadius: 0, maxHeight: 16, color: .white)
        for x in stride(from: 1.0, to: 100, by: 2) { pile.add(atX: x, radius: 2, growth: 16) }
        let before = pile.heights.max() ?? 0
        #expect(before > Tuning.cleanLayer)
        pile.melt(downTo: Tuning.cleanLayer, by: Tuning.cleanMeltRate * 0.5)
        let after = pile.heights.max() ?? 0
        #expect(after < before)
        #expect(after > Tuning.cleanLayer)     // piano: non sparisce di colpo
        for _ in 0..<200 { pile.melt(downTo: Tuning.cleanLayer, by: Tuning.cleanMeltRate * 0.5) }
        #expect(abs((pile.heights.max() ?? 0) - Tuning.cleanLayer) < 0.01)
        #expect(!pile.isEmpty)                 // resta lo strato sottile
    }

    @Test func cleanWindowsStartsOff() {
        #expect(!SnowSettings().cleanWindows)
    }

    // MARK: - Segui la stagione

    @Test(arguments: [
        (month: 1, id: "snow"), (month: 2, id: "snow"), (month: 3, id: "spring"), (month: 5, id: "spring"),
        (month: 6, id: "summer"), (month: 8, id: "summer"), (month: 9, id: "autumn"), (month: 11, id: "autumn"),
        (month: 12, id: "snow"),
    ])
    func followTheSeasonPicksTheEffectFromTheCalendar(month: Int, id: String) {
        #expect(SeasonCalendar.effect(month: month) == id)
        #expect(Seasons.named(id).id == id)
    }

    @Test func followTheSeasonStartsOff() {
        #expect(!SnowSettings().followSeason)
    }

    // MARK: - Schizzi e fulmine

    @Test func onlyRainAndStormSplash() {
        #expect(Rain().splashes)
        #expect(Storm().splashes)
        #expect(!Snow().splashes)
        #expect(!Meteors().splashes)
    }

    @Test func aGlassDropThatReachesAnEdgeSplashesThere() {
        var glass = GlassDrops(rain: GlassRain(beads: 0, size: 2...2, slide: 7, most: 10, color: .white))
        glass.bead(at: CGPoint(x: 100, y: 210), radius: 12)   // pesante: scorre subito
        var splashes: [CGPoint] = []
        for _ in 0..<40 {
            glass.step(dt: 0.05, size: CGSize(width: 400, height: 400), ledges: [Ledge(y: 200, span: 0...400)],
                       amount: 0, calm: false)
            splashes += glass.splashes
        }
        #expect(splashes.count == 1)
        #expect(splashes.first.map { abs($0.y - 200) < 0.01 } == true)
    }

    @Test func aSplashIsSmallerAndShorterThanAStarBurst() {
        let sparks = Sparks()
        sparks.splash(at: CGPoint(x: 100, y: 100), color: .white, calm: false)
        #expect(sparks.count == Tuning.splashDrops)
        #expect(Tuning.splashDrops < Tuning.sparksPerBurst)
        for _ in 0..<12 { sparks.step(dt: 0.05) }
        #expect(sparks.count == 0)
    }

    @Test func theBoltGoesFromTheTopOfTheScreenDownToTheIcon() throws {
        let target = CGPoint(x: 300, y: 60)
        let path = Bolt.points(from: 900, to: target, segments: 10)
        #expect(path.count == 11)
        #expect(try #require(path.first).y == 900)
        #expect(try #require(path.last) == target)
        #expect(zip(path, path.dropFirst()).allSatisfy { $0.y > $1.y })   // scende sempre
    }

    @Test(arguments: [
        (season: "rain", calm: false, trusted: true, strikes: true),
        (season: "storm", calm: false, trusted: true, strikes: true),
        (season: "snow", calm: false, trusted: true, strikes: false),
        (season: "rain", calm: true, trusted: true, strikes: false),
        (season: "storm", calm: false, trusted: false, strikes: false),
    ])
    func theDockBoltOnlyStrikesInTheRainWithAccessibilityAndWithoutReduceMotion(
        season: String, calm: Bool, trusted: Bool, strikes: Bool
    ) {
        #expect(Bolt.strikes(season: Seasons.named(season), reduceMotion: calm, trusted: trusted) == strikes)
    }
}

/// Le voci nuove delle Impostazioni hanno l'inglese nel bundle.
@Test(arguments: [
    ("Vento variabile", "Variable Wind"),
    ("Pausa quando giochi a un videogioco", "Pause While You Play a Video Game"),
    ("Ferma a batteria", "Stop on Battery"),
    ("Finestre pulite", "Clean Windows"),
    ("Segui la stagione", "Follow the Season"),
    ("Schermi", "Displays"),
    ("Energia", "Energy"),
])
func theSecondRoundSettingsAreTranslated(_ italian: String, _ english: String) throws {
    let path = try #require(Bundle.main.path(forResource: "en", ofType: "lproj"))
    let bundle = try #require(Bundle(path: path))
    #expect(bundle.localizedString(forKey: italian, value: nil, table: nil) == english)
}
