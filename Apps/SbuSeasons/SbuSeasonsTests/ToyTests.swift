import AppKit
import SpriteKit
import Testing
@testable import SbuSeasons

/// Un oggetto di prova: un quadrato che conta clic e scosse. Vive solo nei test.
private final class TestBall: Toy {
    var clicks = 0
    var shakes: [Shake] = []
    init(at position: CGPoint) {
        super.init(node: SKSpriteNode(color: .red, size: CGSize(width: 40, height: 40)), at: position)
    }
    override func clicked() { clicks += 1 }
    override func shaken(_ shake: Shake) { shakes.append(shake) }
}

/// La scena con gli oggetti: si posano sui bordi, prendono i clic solo sopra di loro, si trascinano.
@MainActor
struct ToyTests {
    private func scene(reduceMotion: Bool = false) -> SeasonScene {
        let scene = SeasonScene(size: CGSize(width: 1000, height: 800), screenOrigin: .zero, season: Snow())
        scene.reduceMotion = reduceMotion
        return scene
    }

    private func run(_ scene: SeasonScene, from start: TimeInterval = 0, seconds: TimeInterval = 2) {
        for i in 0...Int(seconds * 60) { scene.step(at: start + TimeInterval(i) / 60) }
    }

    private let window = WindowEdge(id: 1, rect: CGRect(x: 100, y: 200, width: 400, height: 200), visible: [100...500])

    @Test func aToyStandsOnAWindowEdge() {
        let scene = scene()
        let ball = TestBall(at: CGPoint(x: 300, y: 700))
        scene.add(ball)
        scene.updateWindows([window], dock: nil, ceiling: 780)
        run(scene)
        #expect(ball.body.position.y == 400)
        #expect(ball.node.position == ball.body.position)
    }

    @Test func clicksGoThroughExceptOverAToy() {
        let scene = scene()
        scene.add(TestBall(at: CGPoint(x: 300, y: 0)))
        #expect(scene.wantsMouse(at: CGPoint(x: 300, y: 20)))
        #expect(!scene.wantsMouse(at: CGPoint(x: 600, y: 20)))
    }

    @Test func aClickWithoutMovingIsAClick() {
        let scene = scene()
        let ball = TestBall(at: CGPoint(x: 300, y: 0))
        scene.add(ball)
        #expect(scene.grab(at: CGPoint(x: 300, y: 20), time: 0))
        scene.letGo(at: CGPoint(x: 301, y: 20), time: 0.1)
        #expect(ball.clicks == 1)
    }

    @Test func aGrabOutsideAToyDoesNothing() {
        let scene = scene()
        scene.add(TestBall(at: CGPoint(x: 300, y: 0)))
        #expect(!scene.grab(at: CGPoint(x: 700, y: 20), time: 0))
    }

    @Test func draggingMovesItAndKeepsTheMouseWhileHeld() {
        let scene = scene()
        let ball = TestBall(at: CGPoint(x: 300, y: 0))
        scene.add(ball)
        _ = scene.grab(at: CGPoint(x: 300, y: 20), time: 0)
        scene.drag(to: CGPoint(x: 600, y: 420), time: 0.1)
        #expect(ball.body.position == CGPoint(x: 600, y: 400))
        #expect(scene.wantsMouse(at: CGPoint(x: 900, y: 700)))   // il cursore è scappato, ma lo teniamo ancora
        scene.letGo(at: CGPoint(x: 600, y: 420), time: 0.2)
        #expect(ball.clicks == 0)
    }

    @Test(arguments: [false, true])
    func aThrowFliesUnlessReduceMotion(reduceMotion: Bool) {
        let scene = scene(reduceMotion: reduceMotion)
        let ball = TestBall(at: CGPoint(x: 300, y: 0))
        scene.add(ball)
        _ = scene.grab(at: CGPoint(x: 300, y: 20), time: 0)
        scene.drag(to: CGPoint(x: 320, y: 220), time: 0.016)
        scene.drag(to: CGPoint(x: 340, y: 420), time: 0.032)
        scene.letGo(at: CGPoint(x: 340, y: 420), time: 0.032)
        run(scene, from: 1, seconds: 0.1)
        if reduceMotion {
            #expect(ball.body.position.x == 340)    // cade dritta
        } else {
            #expect(ball.body.position.x > 350)    // va avanti nella direzione del lancio
        }
    }

    @Test func lettingGoAfterHoldingStillDropsItStraight() {
        let scene = scene()
        let ball = TestBall(at: CGPoint(x: 300, y: 0))
        scene.add(ball)
        _ = scene.grab(at: CGPoint(x: 300, y: 20), time: 0)
        scene.drag(to: CGPoint(x: 320, y: 220), time: 0.016)
        scene.drag(to: CGPoint(x: 340, y: 420), time: 0.032)
        scene.letGo(at: CGPoint(x: 340, y: 420), time: 1.0)
        #expect(ball.body.velocity == .zero)
    }

    @Test func pausingWhileDraggingLetsGoOfTheMouse() {
        let scene = scene()
        scene.add(TestBall(at: CGPoint(x: 300, y: 0)))
        _ = scene.grab(at: CGPoint(x: 300, y: 20), time: 0)
        scene.dropHeld()
        #expect(!scene.wantsMouse(at: CGPoint(x: 900, y: 700)))
    }

    @Test func shakingThePointerReachesTheToys() {
        let scene = scene()
        let ball = TestBall(at: CGPoint(x: 300, y: 0))
        scene.add(ball)
        for (i, x) in [100, 200, 100, 200, 100, 200, 100].enumerated() {
            scene.pointerMoved(to: CGPoint(x: CGFloat(x), y: 400), time: TimeInterval(i) * 0.08)
        }
        #expect(ball.shakes == [.pointer])
    }

    @Test func reduceMotionHalvesTheFlakes() {
        let normal = scene()
        let calm = scene(reduceMotion: true)
        normal.didMove(to: SKView())
        calm.didMove(to: SKView())
        #expect(calm.flakeCount * 2 <= normal.flakeCount + 1)
    }
}
