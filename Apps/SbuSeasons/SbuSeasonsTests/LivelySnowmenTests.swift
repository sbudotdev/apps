import CoreGraphics
import Foundation
import Testing
@testable import SbuSeasons

/// Pupazzi vivi (SBU-187): viaggiano con la finestra e saltano se la scuoti, si rompono se lanciati forte,
/// si tirano palle di neve; lo Yeti cade colpito da una palla. E una palla lanciata oltre il bordo alto torna giù.
@MainActor
struct LivelySnowmenTests {
    private let window = WindowEdge(id: 1, rect: CGRect(x: 100, y: 200, width: 400, height: 200), visible: [100...500])

    private func scene(reduceMotion: Bool = false) -> SeasonScene {
        let scene = SeasonScene(size: CGSize(width: 1000, height: 800), screenOrigin: .zero, season: Snow())
        scene.reduceMotion = reduceMotion
        scene.updateWindows([window], dock: nil, ceiling: 780)
        return scene
    }

    private func run(_ scene: SeasonScene, from start: TimeInterval = 0, seconds: TimeInterval = 2) {
        for i in 0...Int(seconds * 60) { scene.step(at: start + TimeInterval(i) / 60) }
    }

    private func moved(dx: CGFloat, dy: CGFloat) -> WindowEdge {
        let r = window.rect.offsetBy(dx: dx, dy: dy)
        return WindowEdge(id: window.id, rect: r, visible: [r.minX...r.maxX])
    }

    // MARK: - Oltre il bordo alto

    @Test func aBallThrownPastTheTopComesBackDown() {
        let scene = scene()
        let ball = scene.makeSnowball(at: CGPoint(x: 700, y: 600))
        ball.body.release(velocity: CGVector(dx: 0, dy: 5000))
        var highest: CGFloat = 0
        for i in 0...(4 * 60) {
            scene.step(at: TimeInterval(i) / 60)
            highest = max(highest, ball.body.position.y)
        }
        #expect(highest > 800, "è uscita dal bordo alto")
        #expect(scene.toys.contains { $0 === ball })
        #expect(ball.body.position.y == 0 && ball.body.isResting, "ed è tornata giù, sul fondo")
    }

    // MARK: - Con la finestra

    @Test func aSnowmanTravelsWithTheWindowItStandsOn() {
        let scene = scene()
        let snowman = Snowman(at: CGPoint(x: 300, y: 400))
        scene.add(snowman)
        run(scene, seconds: 0.5)
        #expect(snowman.body.position == CGPoint(x: 300, y: 400))
        scene.updateWindows([moved(dx: 20, dy: -10)], dock: nil, ceiling: 780)
        #expect(snowman.body.position == CGPoint(x: 320, y: 390))
        run(scene, from: 1, seconds: 0.5)
        #expect(snowman.body.position == CGPoint(x: 320, y: 390), "e ci resta sopra")
    }

    @Test func aSnowmanElsewhereStaysPut() {
        let scene = scene()
        let snowman = Snowman(at: CGPoint(x: 700, y: 0))
        scene.add(snowman)
        run(scene, seconds: 0.5)
        scene.updateWindows([moved(dx: 20, dy: 0)], dock: nil, ceiling: 780)
        #expect(snowman.body.position == CGPoint(x: 700, y: 0))
    }

    @Test func shakingTheWindowMakesItsSnowmenJump() {
        let scene = scene()
        let snowman = Snowman(at: CGPoint(x: 300, y: 400))
        let other = Snowman(at: CGPoint(x: 700, y: 0))
        scene.add(snowman)
        scene.add(other)
        run(scene, seconds: 0.5)
        scene.windowsShaken([window.id])
        #expect(snowman.body.velocity.dy > 0)
        #expect(other.body.velocity.dy == 0, "solo quelli sulla finestra scossa")
        run(scene, from: 1, seconds: 1.5)
        #expect(scene.toys.contains { $0 === snowman }, "un salto non lo rompe")
    }

    @Test func withReduceMotionNobodyJumps() {
        let scene = scene(reduceMotion: true)
        let snowman = Snowman(at: CGPoint(x: 300, y: 400))
        scene.add(snowman)
        run(scene, seconds: 0.5)
        scene.windowsShaken([window.id])
        #expect(snowman.body.velocity.dy == 0)
    }

    // MARK: - Lanciati forte

    /// Preso e lanciato col mouse: `speed` pt/s verso il basso.
    private func throwDown(_ toy: Toy, in scene: SeasonScene, speed: CGFloat) {
        let start = CGPoint(x: toy.body.position.x, y: toy.body.position.y + 5)
        scene.grab(at: start, time: 0)
        for i in 1...3 {
            scene.drag(to: CGPoint(x: start.x, y: start.y - speed * 0.01 * CGFloat(i)), time: 0.01 * Double(i))
        }
        scene.letGo(at: CGPoint(x: start.x, y: start.y - speed * 0.04), time: 0.04)
    }

    @Test func aSnowballThrownHardBreaksIntoSnow() {
        let scene = scene()
        let ball = scene.makeSnowball(at: CGPoint(x: 700, y: 300))
        throwDown(ball, in: scene, speed: 1400)
        var frame = 0
        while scene.toys.contains(where: { $0 === ball }), frame < 60 {
            scene.step(at: TimeInterval(frame) / 60)
            frame += 1
        }
        #expect(!scene.toys.contains { $0 === ball })
        #expect(scene.grainCount > 0, "diventa neve che cade")
    }

    @Test func aSnowmanThrownHardBreaksToo() {
        let scene = scene()
        let snowman = Snowman(at: CGPoint(x: 700, y: 300))
        scene.add(snowman)
        throwDown(snowman, in: scene, speed: 1400)
        run(scene, seconds: 1)
        #expect(!scene.toys.contains { $0 === snowman })
    }

    @Test func aGentleThrowDoesNotBreakIt() {
        let scene = scene()
        let snowman = Snowman(at: CGPoint(x: 700, y: 300))
        scene.add(snowman)
        throwDown(snowman, in: scene, speed: 300)
        run(scene, seconds: 1.5)
        #expect(scene.toys.contains { $0 === snowman })
    }

    @Test func droppingItFromHighUpDoesNotBreakIt() {
        let scene = scene()
        let snowman = Snowman(at: CGPoint(x: 700, y: 700))
        scene.add(snowman)
        run(scene, seconds: 2)
        #expect(scene.toys.contains { $0 === snowman }, "si rompe se lo lanci, non se cade")
    }

    // MARK: - Palle tra pupazzi

    @Test(arguments: [CGPoint(x: 120, y: 0), CGPoint(x: -200, y: 40), CGPoint(x: 60, y: -30)])
    func aLobLandsOnTheTarget(_ target: CGPoint) {
        let time: CGFloat = 0.8
        let v = lob(from: .zero, to: target, time: time)
        let x = v.dx * time
        let y = v.dy * time - Tuning.toyGravity * time * time / 2
        #expect(abs(x - target.x) < 0.001 && abs(y - target.y) < 0.001)
    }

    @Test func twoSnowmenCloseTogetherThrowASnowball() {
        let scene = scene()
        scene.add(Snowman(at: CGPoint(x: 600, y: 0)))
        scene.add(Snowman(at: CGPoint(x: 720, y: 0)))
        run(scene, seconds: 0.3)
        #expect(scene.snowballFight())
        let ball = scene.toys.compactMap { $0 as? Snowball }.first
        #expect(ball != nil && ball?.body.velocity != .zero)
        run(scene, from: 1, seconds: 1.5)
        #expect(scene.toys.allSatisfy { !($0 is Snowball) }, "la palla si rompe all'arrivo: niente palle sparse")
        #expect(scene.toys.filter { $0 is Snowman }.count == 2)
    }

    @Test func aLonelySnowmanHasNobodyToThrowAt() {
        let scene = scene()
        scene.add(Snowman(at: CGPoint(x: 600, y: 0)))
        scene.add(Snowman(at: CGPoint(x: 300, y: 400)))   // sulla finestra: un altro piano
        run(scene, seconds: 0.3)
        #expect(!scene.snowballFight())
    }

    @Test func withReduceMotionThereAreNoFights() {
        let scene = scene(reduceMotion: true)
        scene.add(Snowman(at: CGPoint(x: 600, y: 0)))
        scene.add(Snowman(at: CGPoint(x: 720, y: 0)))
        run(scene, seconds: 0.3)
        #expect(!scene.snowballFight())
    }

    // MARK: - Yeti colpito

    @Test func aSnowballKnocksTheYetiDown() throws {
        let scene = scene()
        let yeti = try #require(scene.sendYeti(heading: 1))
        yeti.body.position = CGPoint(x: 400, y: 0)
        var exit: VisitorExit?
        scene.onVisitorLeft = { _, e in exit = e }
        let ball = scene.makeSnowball(at: CGPoint(x: 300, y: 30))
        ball.body.release(velocity: CGVector(dx: 600, dy: 100))
        run(scene, seconds: 0.5)
        #expect(yeti.knockedDown)
        #expect(!scene.toys.contains { $0 === ball }, "la palla si rompe sullo Yeti")
        run(scene, from: 1, seconds: Double(Tuning.yetiFall) + 0.5)
        #expect(scene.yeti == nil, "cade e sparisce")
        #expect(exit?.fled == true, "il suo giro finisce lì")
    }

    @Test func aRestingSnowballDoesNotKnockTheYetiDown() throws {
        let scene = scene()
        scene.makeSnowball(at: CGPoint(x: 40, y: 0))
        let yeti = try #require(scene.sendYeti(heading: 1))
        run(scene, seconds: 1.5)
        #expect(!yeti.knockedDown)
    }
}
