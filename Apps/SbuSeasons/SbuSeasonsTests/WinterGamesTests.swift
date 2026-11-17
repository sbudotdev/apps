import AppKit
import SpriteKit
import Testing
@testable import SbuSeasons

/// Spazzaneve, slittino, funivia, albero di Natale, "Togli alberi, neve e slitte", "Metti in pausa i giochi".
@MainActor
struct WinterGamesTests {
    private let size = CGSize(width: 1000, height: 800)
    /// Due finestre a scalini: la seconda più in basso e più a destra.
    private let high = WindowEdge(id: 1, rect: CGRect(x: 100, y: 300, width: 300, height: 200), visible: [100...400])
    private let low = WindowEdge(id: 2, rect: CGRect(x: 380, y: 100, width: 400, height: 200), visible: [380...780])
    private let dockFrame = CGRect(x: 300, y: 0, width: 400, height: 60)

    private func scene(season: any Season = Snow(), reduceMotion: Bool = false) -> SeasonScene {
        let scene = SeasonScene(size: size, screenOrigin: .zero, season: season)
        scene.reduceMotion = reduceMotion
        return scene
    }

    private func run(_ scene: SeasonScene, from start: TimeInterval = 0, seconds: TimeInterval) {
        for i in 0...Int(seconds * 60) { scene.step(at: start + TimeInterval(i) / 60) }
    }

    private func toys<T: Toy>(_ scene: SeasonScene, _ type: T.Type) -> [T] { scene.toys.compactMap { $0 as? T } }

    // MARK: - Spazzaneve

    @Test func thePloughClearsTheDockAndLeavesAHeap() throws {
        let scene = scene()
        scene.updateWindows([], dock: dockFrame, ceiling: 780)
        let dock = try #require(scene.dockPile)
        for x in stride(from: 301.0, to: 700, by: 2) { dock.add(atX: x, radius: 1, growth: 10) }
        let plough = try #require(scene.sendPlough(dockFirst: true))
        let dockTop: CGFloat = dockFrame.maxY - CGFloat(Settings.shared.values.dockInset)
        #expect(plough.body.position.y == dockTop, "parte sopra il Dock")
        run(scene, seconds: 12)
        let left: CGFloat = dock.heights.reduce(0, +)
        #expect(left < 200, "il Dock è pulito (era 2000)")
        #expect(toys(scene, Snowplough.self).isEmpty, "finito il giro esce dallo schermo")
        let heap = try #require(toys(scene, Mound.self).first, "la neve raccolta fa una montagnetta")
        #expect(heap.body.position.x > 900)
    }

    @Test func withoutDockFirstThePloughStartsOnTheHighestWindowAndGoesDown() throws {
        let scene = scene()
        scene.updateWindows([high, low], dock: nil, ceiling: 780)
        let top = try #require(scene.pile(for: high.id))
        for x in stride(from: 101.0, to: 400, by: 2) { top.add(atX: x, radius: 1, growth: 10) }
        let plough = try #require(scene.sendPlough(dockFirst: false))
        #expect(plough.body.position.y == 500)
        run(scene, seconds: 3)   // 283 pt a 150 pt/s, poi la caduta
        #expect(plough.body.position.y == 300, "dalla finestra alta è sceso su quella bassa")
        let left: CGFloat = top.heights.reduce(0, +)
        #expect(left < 150, "la finestra alta è pulita (era 1500)")
    }

    @Test func thereIsOnlyOnePloughAtATime() {
        let scene = scene()
        #expect(scene.sendPlough(dockFirst: true) != nil)
        #expect(scene.sendPlough(dockFirst: true) == nil)
    }

    @Test func aPloughWithoutSnowLeavesNoHeap() {
        let scene = scene()
        scene.sendPlough(dockFirst: true)
        run(scene, seconds: 10)
        #expect(scene.toys.isEmpty)
    }

    // MARK: - Slittino

    @Test func theSledGoesDownFromEdgeToEdge() throws {
        let scene = scene()
        scene.updateWindows([high, low], dock: nil, ceiling: 780)
        let sled = try #require(scene.setUpSledRun())
        #expect(sled.body.position.y == 500, "la pista parte dalla finestra più in alto")
        // Il lancio: un trascinamento verso destra.
        let start = CGPoint(x: sled.body.position.x, y: 505)
        #expect(scene.grab(at: start, time: 0))
        scene.drag(to: CGPoint(x: start.x + 10, y: 505), time: 0.016)
        scene.letGo(at: CGPoint(x: start.x + 20, y: 505), time: 0.032)
        var landings: Set<CGFloat> = []
        for i in 0...180 {
            scene.step(at: 0.05 + TimeInterval(i) / 60)
            if sled.body.isResting { landings.insert(sled.body.position.y) }
        }
        #expect(landings.contains(300), "è scivolato giù sulla finestra più bassa")
        #expect(sled.body.position.x > 400)
    }

    @Test func clickingTheSledPushesIt() throws {
        let scene = scene()
        let sled = try #require(scene.setUpSledRun())
        run(scene, seconds: 0.2)
        let x = sled.body.position.x
        sled.clicked(at: CGPoint(x: 0, y: 5))
        run(scene, from: 1, seconds: 0.5)
        #expect(sled.body.position.x > x + 50)
    }

    @Test func withReduceMotionClickingTheSledDoesNotPushIt() throws {
        let scene = scene(reduceMotion: true)
        let sled = try #require(scene.setUpSledRun())
        run(scene, seconds: 0.2)
        let x = sled.body.position.x
        sled.clicked(at: CGPoint(x: 0, y: 5))
        run(scene, from: 1, seconds: 0.5)
        #expect(sled.body.position.x == x)
    }

    @Test func changingSeasonEndsThePause() {
        let scene = scene()
        scene.toysPaused = true
        scene.setSeason(Summer())
        #expect(!scene.toysPaused, "fuori dall'inverno la voce della pausa è spenta: non si potrebbe togliere")
    }

    @Test func withoutWindowsTheSledStartsOnTheFloor() throws {
        let scene = scene()
        let sled = try #require(scene.setUpSledRun())
        #expect(sled.body.position.y == 0)
    }

    // MARK: - Funivia

    @Test func theCabinRidesWhenTheHookIsOnAWindow() throws {
        let scene = scene()
        scene.updateWindows([high], dock: nil, ceiling: 780)
        let car = try #require(scene.setUpCableCar())
        run(scene, seconds: 1)
        #expect(car.ride == 0, "con il gancio a terra la cabina resta alla stazione")
        // Il gancio trascinato sopra la finestra.
        let hook = CGPoint(x: car.body.position.x, y: car.body.position.y + 4)
        #expect(scene.grab(at: hook, time: 2))
        scene.drag(to: CGPoint(x: 250, y: 520), time: 2.1)
        scene.letGo(at: CGPoint(x: 250, y: 520), time: 2.3)
        run(scene, from: 2.4, seconds: 2)
        #expect(car.body.position.y == 500)
        #expect(car.ride > 0, "la cabina corre sul cavo")
    }

    @Test func theCableCarIsRemovedFromTheMenu() {
        let scene = scene()
        scene.setUpCableCar()
        #expect(scene.hasCableCar)
        #expect(scene.setUpCableCar() == nil, "una sola per schermo")
        scene.removeCableCar()
        #expect(!scene.hasCableCar)
        #expect(scene.toys.isEmpty)
    }

    // MARK: - Albero di Natale

    @Test func clickingABranchHangsABauble() throws {
        let scene = scene()
        let tree = try #require(scene.plantTree())
        tree.clicked(at: CGPoint(x: 0, y: 40))
        tree.clicked(at: CGPoint(x: -10, y: 25))
        #expect(tree.baubles == 2)
    }

    @Test func clickingTheTrunkOrBesideTheTreeHangsNothing() throws {
        let scene = scene()
        let tree = try #require(scene.plantTree())
        tree.clicked(at: CGPoint(x: 0, y: 3))      // il tronco
        tree.clicked(at: CGPoint(x: 27, y: 70))    // accanto alla punta, fuori dai rami
        #expect(tree.baubles == 0)
    }

    @Test func aBaubleIsHungThroughTheEngineClick() throws {
        let scene = scene()
        let tree = try #require(scene.plantTree())
        run(scene, seconds: 0.2)
        let feet = tree.body.position
        let point = CGPoint(x: feet.x, y: feet.y + 40)
        #expect(scene.grab(at: point, time: 1))
        scene.letGo(at: point, time: 1.05)
        #expect(tree.baubles == 1)
    }

    // MARK: - Menu

    @Test func clearingTakesTreesHeapsSledsAndThePloughButNotTheCableCar() {
        let scene = scene()
        scene.plantTree()
        scene.setUpSledRun()
        scene.sendPlough(dockFirst: true)
        scene.add(Mound(at: CGPoint(x: 500, y: 0), snow: 100))
        scene.setUpCableCar()
        scene.makeSnowball(at: CGPoint(x: 700, y: 0))
        scene.clearWinterPlay()
        #expect(scene.toys.count == 2)
        #expect(scene.hasCableCar)
        #expect(toys(scene, Snowball.self).count == 1, "le palle hanno il loro comando")
    }

    @Test func pausedToysDoNotMoveAndCannotBeGrabbed() throws {
        let scene = scene()
        let plough = try #require(scene.sendPlough(dockFirst: true))
        run(scene, seconds: 0.2)
        scene.toysPaused = true
        let x = plough.body.position.x
        run(scene, from: 1, seconds: 1)
        #expect(plough.body.position.x == x)
        #expect(!scene.wantsMouse(at: CGPoint(x: x, y: 5)))
        scene.toysPaused = false
        run(scene, from: 3, seconds: 0.5)
        #expect(plough.body.position.x > x)
    }

    @Test func winterGamesAreOnlyInWinter() {
        let scene = scene(season: Summer())
        #expect(scene.sendPlough(dockFirst: true) == nil)
        #expect(scene.setUpSledRun() == nil)
        #expect(scene.setUpCableCar() == nil)
        #expect(scene.plantTree() == nil)
    }

    @Test func changingSeasonTakesAwayTheWinterGames() {
        let scene = scene()
        scene.plantTree()
        scene.setUpSledRun()
        scene.setUpCableCar()
        scene.setSeason(Summer())
        #expect(scene.toys.isEmpty)
    }
}
