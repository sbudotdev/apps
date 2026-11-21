import CoreGraphics
import Foundation
import Testing
@testable import SbuSeasons

/// Un oggetto ricevuto in un file `.sbuseasons` (SBU-200): pupazzi e alberi li porta il trenino sullo schermo principale,
/// solo d'inverno; le decorazioni della scrivania arrivano tutto l'anno, in mezzo allo schermo.
@MainActor
struct ReceivedToyTests {
    private let size = CGSize(width: 1000, height: 800)

    private func scene(season: any Season = Snow(), reduceMotion: Bool = false) -> SeasonScene {
        let scene = SeasonScene(size: size, screenOrigin: .zero, season: season)
        scene.reduceMotion = reduceMotion
        scene.updateWindows([], dock: nil, ceiling: 780)
        return scene
    }

    private func run(_ scene: SeasonScene, seconds: TimeInterval) {
        for i in 0...Int(seconds * 60) { scene.step(at: TimeInterval(i) / 60) }
    }

    private var dressed: SnowmanLook {
        var look = SnowmanLook()
        look.hat = .pirate
        return look
    }

    @Test func theTrainBringsTheSnowmanAndDropsItInTheMiddle() throws {
        let scene = scene()
        #expect(scene.receive(Snowman(at: .zero, look: dressed)))
        #expect(scene.train != nil, "lo porta il trenino")
        #expect(scene.toys.compactMap { $0 as? Snowman }.isEmpty, "non è ancora arrivato")
        run(scene, seconds: 12)
        let snowman = try #require(scene.toys.compactMap { $0 as? Snowman }.first)
        #expect(snowman.look == dressed)
        #expect(abs(snowman.body.position.x - size.width / 2) < size.width * 0.2)
        #expect(snowman.body.position.y < 1, "è caduto sul fondo")
        #expect(!scene.toys.contains { $0 is Gift }, "niente regalo dell'elfo insieme")
    }

    @Test func withReduceMotionTheSnowmanIsThereAtOnce() {
        let scene = scene(reduceMotion: true)
        #expect(scene.receive(Snowman(at: .zero, look: dressed)))
        #expect(scene.train == nil)
        #expect(scene.toys.contains { ($0 as? Snowman)?.look == dressed })
    }

    @Test func withTheToysPausedOrTheTrainBusyItIsThereAtOnce() throws {
        let paused = scene()
        paused.toysPaused = true
        #expect(paused.receive(Snowman(at: .zero, look: dressed)))
        #expect(paused.toys.contains { $0 is Snowman })

        let busy = scene()
        try #require(busy.sendTrain(heading: 1, carriesGift: true) != nil)
        #expect(busy.receive(ChristmasTree(at: .zero)))
        #expect(busy.toys.contains { $0 is ChristmasTree })
    }

    @Test func pausingWhileTheTrainBringsItLeavesItThere() {
        let scene = scene()
        scene.receive(Snowman(at: .zero, look: dressed))
        scene.toysPaused = true
        #expect(scene.train == nil)
        #expect(scene.toys.contains { ($0 as? Snowman)?.look == dressed })
    }

    @Test func outsideWinterSnowmenAndTreesDoNotArrive() {
        let scene = scene(season: Summer())
        #expect(!scene.receive(Snowman(at: .zero, look: dressed)))
        #expect(!scene.receive(ChristmasTree(at: .zero)))
        #expect(scene.toys.isEmpty)
    }

    @Test func aReceivedTreeKeepsTheLimitOfTrees() {
        let scene = scene(reduceMotion: true)
        for _ in 0..<(Tuning.maxTrees + 2) { scene.receive(ChristmasTree(at: .zero)) }
        #expect(scene.toys.compactMap { $0 as? ChristmasTree }.count == Tuning.maxTrees)
    }

    @Test func aDeskDecorationArrivesInTheMiddleOfTheScreenAsANewOne() {
        guard case .decoration(let item) = ToyFile.decoration(DeskItem(kind: .candle, screen: "B", center: CGPoint(x: 5, y: 5))) else { return }
        let arrived = item.arriving(on: "Main", size: size)
        #expect(arrived.screen == "Main")
        #expect(arrived.center == CGPoint(x: size.width / 2, y: size.height / 2))
        #expect(arrived.id != item.id)
    }

    @Test func longLightsArriveInsideTheScreen() throws {
        let file = try ToyFile(data: Data(#"{"format":"sbuseasons","version":1,"decoration":{"kind":"lights","scale":1,"rotation":0,"span":[1600,0]}}"#.utf8))
        guard case .decoration(let item) = file else { Issue.record(); return }
        let arrived = item.arriving(on: "Main", size: size)
        #expect(arrived.frame.minX >= 0 && arrived.frame.maxX <= size.width, "le luci più lunghe dello schermo si accorciano")
    }
}
