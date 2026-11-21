import CoreGraphics
import Foundation
import Testing
@testable import SbuSeasons

/// Lo Yeti che prova a portarsi via un pupazzo e il trenino con l'elfo che lascia un regalo (SBU-178).
@MainActor
struct VisitorsTests {
    private let size = CGSize(width: 1000, height: 800)

    private func scene(origin: CGPoint = .zero, reduceMotion: Bool = false) -> SeasonScene {
        let scene = SeasonScene(size: size, screenOrigin: origin, season: Snow())
        scene.reduceMotion = reduceMotion
        scene.updateWindows([], dock: nil, ceiling: 780)
        return scene
    }

    private func run(_ scene: SeasonScene, from start: TimeInterval = 0, seconds: TimeInterval) {
        for i in 0...Int(seconds * 60) { scene.step(at: start + TimeInterval(i) / 60) }
    }

    private func snowmen(_ scene: SeasonScene) -> [Snowman] { scene.toys.compactMap { $0 as? Snowman } }

    // MARK: - Yeti

    @Test func theYetiTakesASnowmanAndWalksOffWithIt() throws {
        let scene = scene()
        var look = SnowmanLook()
        look.hat = .beanie
        scene.add(Snowman(at: CGPoint(x: 300, y: 0), look: look))
        var exit: VisitorExit?
        scene.onVisitorLeft = { _, e in exit = e }
        try #require(scene.sendYeti(heading: 1) != nil)
        run(scene, seconds: 30)
        #expect(snowmen(scene).isEmpty, "se l'è portato via")
        #expect(scene.yeti == nil)
        #expect(exit?.carrying == look)
        #expect(exit?.heading == 1)
    }

    @Test func aClickScaresTheYetiAwayAndTheSnowmanStays() throws {
        let scene = scene()
        let snowman = Snowman(at: CGPoint(x: 200, y: 0))
        scene.add(snowman)
        let yeti = try #require(scene.sendYeti(heading: 1))
        run(scene, seconds: 6)
        try #require(yeti.carried === snowman, "l'ha preso")
        var exit: VisitorExit?
        scene.onVisitorLeft = { _, e in exit = e }
        yeti.clicked()
        run(scene, from: 10, seconds: 10)
        #expect(snowmen(scene).count == 1)
        #expect(!snowman.body.isHeld)
        #expect(scene.yeti == nil)
        #expect(exit?.fled == true)
    }

    @Test func theYetiJumpsOnAWindowToFetchASnowman() throws {
        let scene = scene()
        scene.updateWindows([WindowEdge(id: 1, rect: CGRect(x: 300, y: 100, width: 300, height: 200), visible: [300...600])],
                            dock: nil, ceiling: 780)
        let snowman = Snowman(at: CGPoint(x: 450, y: 300))
        scene.add(snowman)
        let yeti = try #require(scene.sendYeti(heading: 1))
        run(scene, seconds: 15)
        #expect(yeti.carried === snowman || !scene.toys.contains { $0 === snowman })
    }

    @Test func withReduceMotionTheYetiDoesNotJumpButStillGetsThere() throws {
        let scene = scene(reduceMotion: true)
        scene.updateWindows([WindowEdge(id: 1, rect: CGRect(x: 300, y: 100, width: 300, height: 200), visible: [300...600])],
                            dock: nil, ceiling: 780)
        let snowman = Snowman(at: CGPoint(x: 450, y: 300))
        scene.add(snowman)
        let yeti = try #require(scene.sendYeti(heading: 1))
        var highest: CGFloat = 0
        for i in 0...(60 * 50) {
            scene.step(at: TimeInterval(i) / 60)
            highest = max(highest, yeti.body.position.y)
        }
        #expect(highest <= 300.5, "non salta oltre il bordo")
        #expect(!scene.toys.contains { $0 === snowman })
    }

    @Test func pausingTheToysSendsTheYetiAwayAndDropsTheSnowman() throws {
        let scene = scene()
        let snowman = Snowman(at: CGPoint(x: 200, y: 0))
        scene.add(snowman)
        let yeti = try #require(scene.sendYeti(heading: 1))
        run(scene, seconds: 6)
        try #require(yeti.carried === snowman)
        scene.toysPaused = true
        #expect(scene.yeti == nil)
        #expect(snowmen(scene).count == 1)
        #expect(!snowman.body.isHeld)
        #expect(scene.sendYeti(heading: 1) == nil, "in pausa non entra")
    }

    @Test func theYetiCanBeClickedButNotDragged() throws {
        let scene = scene()
        let yeti = try #require(scene.sendYeti(heading: -1))
        run(scene, seconds: 2)
        let feet = yeti.body.position
        #expect(scene.wantsMouse(at: CGPoint(x: feet.x, y: 20)))
        scene.grab(at: CGPoint(x: feet.x, y: 20), time: 10)
        scene.drag(to: CGPoint(x: feet.x, y: 400), time: 10.1)
        #expect(yeti.body.position.y < 1)
        scene.letGo(at: CGPoint(x: feet.x, y: 400), time: 10.2)
    }

    // MARK: - Trenino

    @Test func theTrainCrossesTheScreenAndLeavesAGiftFromTheElf() throws {
        let scene = scene()
        var left = false
        scene.onVisitorLeft = { kind, _ in left = kind == .train }
        try #require(scene.sendTrain(heading: -1, carriesGift: true) != nil)
        run(scene, seconds: 12)
        #expect(scene.train == nil)
        #expect(left)
        let gift = try #require(scene.toys.compactMap { $0 as? Gift }.first)
        #expect(gift.fromElf)
        #expect(gift.body.isResting && gift.body.position.y < 1, "è caduto sul fondo")
    }

    @Test func withReduceMotionTheTrainDoesNotCrossButTheGiftArrives() {
        let scene = scene(reduceMotion: true)
        scene.sendTrain(heading: 1, carriesGift: true)
        #expect(scene.train == nil)
        #expect(scene.toys.contains { ($0 as? Gift)?.fromElf == true })
    }

    @Test func pausingTheToysTakesTheTrainAway() throws {
        let scene = scene()
        try #require(scene.sendTrain(heading: 1, carriesGift: false) != nil)
        scene.toysPaused = true
        #expect(scene.train == nil)
    }

    // MARK: - Il regalo dell'elfo

    @Test(arguments: [(0.0, ElfPresent.decoration(.bauble)), (0.99, .decoration(.angel))])
    func withATreeTheGiftIsADecoration(_ roll: Double, _ present: ElfPresent) {
        #expect(ElfPresent.pick(hasTree: true, snowman: nil, roll: roll) == present)
    }

    @Test func aSnowmanGetsSomethingItDoesNotWearYet() {
        var dressed = SnowmanLook()
        dressed.hat = .topHat
        dressed.scarf = .red
        for roll in stride(from: 0.0, to: 1, by: 0.1) {
            let present = ElfPresent.pick(hasTree: false, snowman: SnowmanLook(), roll: roll)
            #expect([.hat(.topHat), .hat(.beanie), .scarf(.red), .scarf(.green)].contains(present))
        }
        #expect(ElfPresent.pick(hasTree: false, snowman: dressed, roll: 0.5) == .tree, "vestito di tutto: un albero")
    }

    @Test func withNothingOnTheScreenTheGiftIsATree() {
        #expect(ElfPresent.pick(hasTree: false, snowman: nil, roll: 0.3) == .tree)
        let scene = scene()
        let gift = Gift(at: CGPoint(x: 500, y: 0), fromElf: true)
        scene.add(gift)
        gift.clicked()
        #expect(scene.toys.contains { $0 is ChristmasTree })
        #expect(!scene.toys.contains { $0 is GingerbreadMan })
    }

    @Test func openingTheElfGiftDecoratesTheTree() {
        let scene = scene()
        let tree = ChristmasTree(at: CGPoint(x: 400, y: 0))
        scene.add(tree)
        let gift = Gift(at: CGPoint(x: 500, y: 0), fromElf: true)
        scene.add(gift)
        gift.clicked()
        #expect(tree.look.decorations.count == 1)
    }

    // MARK: - Più schermi

    @Test func theTrainCrossesEveryScreenOneAfterTheOther() throws {
        let left = scene()
        let right = scene(origin: CGPoint(x: 1000, y: 0))
        let visitors = Visitors(random: { 0.9 })   // verso destra, regalo sull'ultima tappa
        visitors.scenes = [right, left]
        #expect(visitors.send(.train))
        #expect(left.train != nil && right.train == nil, "parte dallo schermo a sinistra")
        run(left, seconds: 10)
        #expect(left.train == nil)
        #expect(right.train != nil, "entra nel vicino")
        run(right, from: 20, seconds: 10)
        #expect(!visitors.isVisiting(.train))
        #expect(right.toys.contains { ($0 as? Gift)?.fromElf == true })
    }

    @Test func theYetiCarriesTheSnowmanIntoTheNextScreen() throws {
        let left = scene()
        let right = scene(origin: CGPoint(x: 1000, y: 0))
        left.add(Snowman(at: CGPoint(x: 600, y: 0)))
        let visitors = Visitors(random: { 0.9 })
        visitors.scenes = [left, right]
        visitors.send(.yeti)
        run(left, seconds: 30)
        let yeti = try #require(right.yeti)
        #expect(yeti.carried != nil)
    }

    @Test func nobodyComesWhileTheToysArePaused() {
        let scene = scene()
        let visitors = Visitors()
        visitors.scenes = [scene]
        scene.toysPaused = true
        #expect(!visitors.send(.train))
        #expect(!visitors.send(.yeti))
    }

    @Test func theYetiComesAloneOnlyIfThereIsASnowman() {
        let scene = scene()
        let visitors = Visitors(random: { 0 })
        visitors.passesAlone = { $0 == .yeti }
        visitors.scenes = [scene]
        visitors.tick(at: 0)
        visitors.tick(at: 10_000)
        #expect(scene.yeti == nil)
        scene.add(Snowman(at: CGPoint(x: 500, y: 0)))
        visitors.tick(at: 20_000)
        #expect(scene.yeti != nil)
    }

    @Test func pausedOrSwitchedOffTheyDoNotComeAlone() {
        let scene = scene()
        let visitors = Visitors(random: { 0 })
        visitors.passesAlone = { _ in false }
        visitors.scenes = [scene]
        visitors.tick(at: 0)
        visitors.tick(at: 10_000)
        #expect(scene.train == nil)
    }
}
