import AppKit
import SpriteKit
import Testing
@testable import SbuSeasons

/// I personaggi (volpe, cincia con mangiatoia, baita, lanterna, renna) e la notte con la candela.
@MainActor
struct FiguresTests {
    private let size = CGSize(width: 1000, height: 800)
    private let window = WindowEdge(id: 1, rect: CGRect(x: 100, y: 300, width: 300, height: 200), visible: [100...400])

    private func scene(season: any Season = Snow(), reduceMotion: Bool = false) -> SeasonScene {
        let scene = SeasonScene(size: size, screenOrigin: .zero, season: season)
        scene.reduceMotion = reduceMotion
        return scene
    }

    private func run(_ scene: SeasonScene, from start: TimeInterval = 0, seconds: TimeInterval) {
        for i in 0...Int(seconds * 60) { scene.step(at: start + TimeInterval(i) / 60) }
    }

    private func figure<T: Figure>(_ scene: SeasonScene, _ type: T.Type) throws -> T {
        try #require(scene.toys.compactMap { $0 as? T }.first)
    }

    // MARK: - Menu

    @Test(arguments: FigureKind.allCases)
    func eachFigureComesAndGoesFromTheMenu(_ kind: FigureKind) {
        let scene = scene()
        #expect(scene.toggleFigure(kind))
        #expect(scene.hasFigure(kind))
        #expect(scene.toys.count == 1)
        #expect(!scene.toggleFigure(kind), "la seconda volta lo toglie")
        #expect(scene.toys.isEmpty)
    }

    @Test func figuresAreOnlyForWinterAndLeaveWhenTheSeasonChanges() {
        let summer = scene(season: Summer())
        #expect(!summer.toggleFigure(.fox))
        #expect(summer.toys.isEmpty)

        let scene = scene()
        FigureKind.allCases.forEach { scene.toggleFigure($0) }
        scene.setSeason(Summer())
        #expect(scene.toys.isEmpty)
    }

    @Test func theReindeerStartsOnTopOfTheHighestWindow() throws {
        let scene = scene()
        scene.updateWindows([window], dock: nil, ceiling: 780)
        scene.toggleFigure(.reindeer)
        let reindeer = try figure(scene, Reindeer.self)
        #expect(reindeer.body.position.y == 500)
        #expect((100...400).contains(reindeer.body.position.x))
    }

    // MARK: - Volpe

    @Test func theFoxSleepsUntilClickedThenSniffsWalksAndSleepsAgain() {
        #expect(Fox.mood(awakeFor: nil) == .asleep)
        #expect(Fox.mood(awakeFor: 0) == .sniffing)
        #expect(Fox.mood(awakeFor: Tuning.foxSniff + 0.1) == .walking)
        #expect(Fox.mood(awakeFor: Tuning.foxAwake + 0.1) == .asleep)
    }

    @Test func aClickedFoxWalksAlongItsLedgeAndGoesBackToSleep() throws {
        let scene = scene()
        scene.updateWindows([window], dock: nil, ceiling: 780)
        let fox = Fox(at: CGPoint(x: 250, y: 500))
        scene.add(fox)
        run(scene, seconds: 1)
        #expect(fox.body.position.x == 250, "dorme: non si muove")
        fox.clicked()
        run(scene, from: 2, seconds: Tuning.foxAwake - 1)
        #expect(fox.body.position.x != 250, "sveglia, cammina")
        #expect(fox.body.position.y == 500, "senza cadere dal bordo")
        run(scene, from: 2 + Tuning.foxAwake, seconds: 1.5)
        #expect(fox.mood == .asleep, "e poi torna a dormire")
    }

    // MARK: - Renna e passo

    @Test func walkersTurnBeforeTheEndOfTheirLedge() {
        #expect(Pacing.heading(x: 200, span: 100...400, heading: 1, margin: 10) == 1)
        #expect(Pacing.heading(x: 395, span: 100...400, heading: 1, margin: 10) == -1)
        #expect(Pacing.heading(x: 105, span: 100...400, heading: -1, margin: 10) == 1)
    }

    @Test func theNoseGlowsWhenTheCursorIsNear() {
        #expect(Reindeer.noseGlow(distance: 0) == 1)
        #expect(Reindeer.noseGlow(distance: Tuning.reindeerNoseReach / 2) == 0.5)
        #expect(Reindeer.noseGlow(distance: Tuning.reindeerNoseReach * 2) == 0)
    }

    @Test func theReindeerWalksOnTheWindowAndStaysOnIt() throws {
        let scene = scene()
        scene.updateWindows([window], dock: nil, ceiling: 780)
        scene.toggleFigure(.reindeer)
        let reindeer = try figure(scene, Reindeer.self)
        let start = reindeer.body.position.x
        run(scene, seconds: 20)
        #expect(reindeer.body.position.x != start)
        #expect(reindeer.body.position.y == 500)
    }

    // MARK: - Cincia e mangiatoia

    @Test func aClickFillsTheFeederAndTheTitEatsItEmpty() {
        var tray = SeedTray()
        #expect(tray.seeds == 0)
        let pecksEmpty = tray.step(dt: 10)
        #expect(!pecksEmpty, "vuota: niente da beccare")
        tray.fill()
        #expect(tray.seeds == Tuning.feederSeeds)
        let tooSoon = tray.step(dt: Tuning.titPeck / 2)
        let onTime = tray.step(dt: Tuning.titPeck / 2)
        #expect(!tooSoon)
        #expect(onTime, "un seme ogni `titPeck` secondi")
        #expect(tray.seeds == Tuning.feederSeeds - 1)
        for _ in 0..<Tuning.feederSeeds { _ = tray.step(dt: Tuning.titPeck) }
        #expect(tray.seeds == 0)
    }

    @Test func theTitComesOnlyWhenThereAreSeeds() {
        let feeder = Feeder(at: CGPoint(x: 300, y: 0))
        #expect(!feeder.titIsHere)
        feeder.clicked()
        #expect(feeder.titIsHere)
        for _ in 0...Int(Tuning.titPeck * CGFloat(Tuning.feederSeeds) * 60) { feeder.step(dt: 1.0 / 60) }
        #expect(!feeder.titIsHere, "finiti i semi vola via")
    }

    // MARK: - Baita e lanterna

    @Test func aClickLightsTheCabinFireAndTheLantern() {
        let cabin = Cabin(at: CGPoint(x: 300, y: 0))
        let lantern = Lantern(at: CGPoint(x: 500, y: 0))
        #expect(!cabin.isLit && !lantern.isLit)
        cabin.clicked()
        lantern.clicked()
        #expect(cabin.isLit && lantern.isLit)
        lantern.clicked()
        #expect(!lantern.isLit, "la lanterna si spegne col secondo clic")
    }

    @Test func theCabinSmokesOnlyWhenLitAndWithoutReduceMotion() throws {
        for calm in [false, true] {
            let scene = scene(reduceMotion: calm)
            scene.toggleFigure(.cabin)
            let cabin = try figure(scene, Cabin.self)
            run(scene, seconds: 1)
            #expect(cabin.node.children.count(where: { $0.name == "smoke" }) == 0, "spenta: niente fumo")
            cabin.clicked()
            run(scene, from: 2, seconds: 2)
            let puffs = cabin.node.children.count(where: { $0.name == "smoke" })
            #expect(calm ? puffs == 0 : puffs > 0)
        }
    }

    // MARK: - Notte

    @Test(arguments: [
        (NightMode.off, 22, 23, false),
        (.always, 22, 12, true),
        (.late, 22, 21, false),
        (.late, 22, 22, true),
        (.late, 22, 3, true),
        (.late, 22, 6, false),
        (.late, 1, 0, false),
        (.late, 1, 2, true),
    ])
    func itIsNightFromTheChosenHourUntilMorning(_ mode: NightMode, _ start: Int, _ hour: Int, _ night: Bool) {
        #expect(NightClock.isNight(mode: mode, startHour: start, hour: hour) == night)
    }

    @Test func atNightTheScreenDimsAndTheCandleIsLit() {
        let scene = scene(season: Clear())
        let saved = Settings.shared.values
        defer { Settings.shared.values = saved }
        Settings.shared.values.night = .off
        run(scene, seconds: 1.2)
        #expect(!scene.night.isOn)
        Settings.shared.values.night = .always
        run(scene, from: 2, seconds: 1.2)
        #expect(scene.night.isOn, "si accende entro un secondo dal cambio")
        Settings.shared.values.night = .off
        run(scene, from: 4, seconds: 1.2)
        #expect(!scene.night.isOn)
    }

    @Test func theNightSettingsHaveDefaultsAndSurviveOlderSaves() throws {
        #expect(SnowSettings().night == .off)
        #expect(SnowSettings().nightStart == 22)
        let old = try JSONSerialization.data(withJSONObject: ["wind": 20.0])
        let settings = SnowSettings(saved: old)
        #expect(settings.wind == 20 && settings.night == .off)
    }
}
