import AppKit
import SpriteKit
import Testing
@testable import SbuSeasons

/// Pioggia sul vetro, nebbia, nuvole e temporale (SBU-52): il motore per banchi, lampi e gocce, e le quattro stagioni.
@MainActor
struct WeatherTests {
    private let size = CGSize(width: 400, height: 300)
    private let rain = GlassRain(beads: 0, size: 2...2, slide: 5, most: 1000, color: .white)

    private func run(_ scene: SeasonScene, steps: Int, from start: TimeInterval = 1) {
        var t = start
        for _ in 0..<steps { scene.step(at: t); t += 0.05 }
    }

    private func scene(_ season: any Season) -> SeasonScene {
        let scene = SeasonScene(size: size, screenOrigin: .zero, season: Clear())
        scene.setSeason(season)   // senza una view, le particelle e i banchi nascono qui
        return scene
    }

    // MARK: - Gocce sul vetro (logica)

    @Test func dropsThatTouchMergeAndKeepTheirWater() throws {
        var glass = GlassDrops(rain: rain)
        glass.bead(at: CGPoint(x: 100, y: 100), radius: 3)
        glass.bead(at: CGPoint(x: 104, y: 100), radius: 4)
        let drop = try #require(glass.drops.first)
        #expect(glass.drops.count == 1)
        #expect(abs(drop.radius - 5) < 0.01)   // le aree si sommano: 3² + 4² = 5²
    }

    @Test func aSmallDropStaysPut() {
        var glass = GlassDrops(rain: rain)
        glass.bead(at: CGPoint(x: 100, y: 200), radius: 3)
        for _ in 0..<40 { glass.step(dt: 0.05, size: size, ledges: [], amount: 1, calm: false) }
        #expect(glass.drops.map(\.position) == [CGPoint(x: 100, y: 200)])
    }

    /// Una goccia pesante scorre giù, raccoglie quelle che trova sulla strada e sparisce sotto lo schermo.
    @Test func aHeavyDropRunsDownGatheringDropsOnItsWay() {
        var glass = GlassDrops(rain: rain)
        glass.bead(at: CGPoint(x: 200, y: 280), radius: 6)
        glass.bead(at: CGPoint(x: 200, y: 150), radius: 3)
        glass.step(dt: 0.05, size: size, ledges: [], amount: 1, calm: false)
        let start = glass.drops.first { $0.radius >= 6 }?.position.y ?? 0
        var merged = false
        for _ in 0..<60 {
            glass.step(dt: 0.05, size: size, ledges: [], amount: 1, calm: false)
            if !glass.drops.contains(where: { $0.position.y > 140 && $0.position.y < 160 && $0.radius == 3 }) { merged = true }
        }
        #expect(merged)
        #expect((glass.drops.map(\.position.y).max() ?? 0) < start)
        for _ in 0..<200 { glass.step(dt: 0.05, size: size, ledges: [], amount: 1, calm: false) }
        #expect(!glass.drops.contains { $0.radius >= 4 })   // la goccia grossa è uscita in fondo
    }

    /// Arrivata sul bordo scoperto di una finestra cade giù, libera, più veloce di come scorreva.
    @Test func aRunningDropFallsOffAWindowEdge() throws {
        var glass = GlassDrops(rain: rain)
        glass.bead(at: CGPoint(x: 200, y: 250), radius: 6)
        let ledge = Ledge(y: 200, span: 100...300)
        var fell: Drop?
        for _ in 0..<100 where fell == nil {
            glass.step(dt: 0.05, size: size, ledges: [ledge], amount: 1, calm: false)
            fell = glass.drops.first { $0.falling }
        }
        let edge = try #require(fell)
        #expect(edge.position.y < 200)
        for _ in 0..<3 { glass.step(dt: 0.05, size: size, ledges: [ledge], amount: 1, calm: false) }
        let drop = try #require(glass.drops.first { $0.id == edge.id })
        #expect(drop.speed > glass.runSpeed(drop.radius, calm: false) * 2)
    }

    @Test func rainBeadsOnTheGlassAndFollowsTheIntensity() {
        let rain = GlassRain(beads: 20, size: 1...1.5, slide: 50, most: 10_000, color: .white)
        func count(amount: CGFloat, calm: Bool) -> Int {
            var glass = GlassDrops(rain: rain)
            for _ in 0..<100 { glass.step(dt: 0.1, size: CGSize(width: 1440, height: 900), ledges: [], amount: amount, calm: calm) }
            return glass.drops.count
        }
        let normal = count(amount: 1, calm: false)
        #expect(normal > 120)   // 20 al secondo per 10 s, meno quelle che si sono unite
        #expect(count(amount: 0.5, calm: false) < normal * 3 / 4)
        #expect(count(amount: 1, calm: true) < normal * 3 / 4)
    }

    @Test func withReduceMotionDropsRunSlower() {
        let glass = GlassDrops(rain: rain)
        #expect(glass.runSpeed(8, calm: true) < glass.runSpeed(8, calm: false))
    }

    // MARK: - Lampi

    @Test func aFlashIsTwoBrightPeaksThenFades() {
        #expect(Lightning.flash(at: -0.1) == 0)
        #expect(Lightning.flash(at: 0.04) == 1)
        #expect(Lightning.flash(at: 0.13) < Lightning.flash(at: 0.22))   // il secondo bagliore
        #expect(Lightning.flash(at: 0.5) > 0)
        #expect(Lightning.flash(at: 0.8) == 0)
    }

    // MARK: - Le stagioni

    @Test func mistLiesLowAndDriftsSlowlyRight() throws {
        let scene = scene(Mist())
        let banks = scene.sky.bankNodes
        #expect(banks.count >= 3)
        #expect(banks.allSatisfy { $0.position.y < size.height * 0.4 })
        #expect(banks.allSatisfy { $0.alpha < 0.7 })   // con la texture già leggera: sotto si deve poter lavorare
        let before = banks.map(\.position.x)
        run(scene, steps: 20)
        let moved = zip(before, banks.map(\.position.x)).map { $1 - $0 }
        #expect(moved.allSatisfy { $0 > 0 && $0 < 20 })   // 1 s: piano, verso destra
    }

    @Test func cloudsCrossTheTopOfTheScreenAndComeBack() throws {
        let scene = scene(Clouds())
        let banks = scene.sky.bankNodes
        #expect(!banks.isEmpty)
        #expect(banks.allSatisfy { $0.position.y > size.height * 0.75 })
        run(scene, steps: 2_000)   // 100 s: su uno schermo largo 400 sono uscite tutte e rientrate
        #expect(banks.allSatisfy { $0.parent != nil && $0.position.x - $0.size.width / 2 < size.width })
    }

    @Test func moreIntensityMoreBanks() {
        let saved = Settings.shared.values.flakeCount
        defer { Settings.shared.values.flakeCount = saved }
        let wide = CGSize(width: 1440, height: 900)
        Settings.shared.values.flakeCount = SnowSettings().flakeCount
        let scene = SeasonScene(size: wide, screenOrigin: .zero, season: Clear())
        scene.setSeason(Clouds())
        let medium = Set(scene.sky.bankNodes.map(ObjectIdentifier.init))
        Settings.shared.values.flakeCount = SnowSettings().flakeCount * 2
        scene.step(at: 1)
        scene.step(at: 1.02)
        let more = Set(scene.sky.bankNodes.map(ObjectIdentifier.init))
        #expect(more.count > medium.count)
        #expect(medium.isSubset(of: more))   // quelle che c'erano restano
    }

    @Test func aStormFlashesTheCloudsNowAndThen() {
        let scene = scene(Storm())
        #expect(!scene.sky.bankNodes.isEmpty)
        var flashes = 0, wasDark = true
        for i in 0..<800 {   // 40 s: un lampo ogni 6–18 s
            scene.step(at: 1 + Double(i) * 0.05)
            if scene.sky.flash > 0.3, wasDark { flashes += 1 }
            wasDark = scene.sky.flash == 0
        }
        #expect(flashes >= 2)
    }

    @Test func noLightningWithReduceMotion() {
        let scene = scene(Storm())
        scene.reduceMotion = true
        var brightest: CGFloat = 0
        for i in 0..<800 { scene.step(at: 1 + Double(i) * 0.05); brightest = max(brightest, scene.sky.flash) }
        #expect(brightest == 0)
    }

    /// La pioggia del temporale cade di traverso ma copre tutto lo schermo, anche il lato da cui viene.
    @Test func stormRainCoversTheWholeScreen() {
        let wide = CGSize(width: 1440, height: 900)
        let scene = SeasonScene(size: wide, screenOrigin: .zero, season: Clear())
        scene.setSeason(Storm())
        var seen: [CGPoint] = []
        var t: TimeInterval = 1
        for _ in 0..<100 {
            scene.step(at: t); t += 0.05
            seen += scene.children.compactMap { $0 as? SKSpriteNode }.map(\.position).filter { $0.y > 0 && $0.y < wide.height }
        }
        // In ogni decimo dello schermo, da sinistra a destra, passa la pioggia.
        let columns = Set(seen.filter { $0.x >= 0 && $0.x < wide.width }.map { Int($0.x / wide.width * 10) })
        #expect(columns == Set(0..<10))
    }

    @Test func rainOnTheGlassMakesDropsAndNothingFalls() {
        let scene = scene(Rain())
        run(scene, steps: 100)
        #expect(scene.flakeCount == 0)
        #expect(!(scene.glass.model?.drops.isEmpty ?? true))
        scene.setSeason(Snow())
        #expect(scene.glass.children.isEmpty)   // cambiando stagione il vetro si asciuga
    }

    @Test func weatherNeverSettles() {
        for season: any Season in [Rain(), Storm(), Mist(), Clouds()] { #expect(!season.settles) }
    }
}
