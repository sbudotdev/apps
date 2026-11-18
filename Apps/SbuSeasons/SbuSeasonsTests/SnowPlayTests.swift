import AppKit
import SpriteKit
import Testing
@testable import SbuSeasons

/// Palle di neve, pupazzo, neve che scivola via da una finestra spostata veloce, palla di vetro.
@MainActor
struct SnowPlayTests {
    private let window = WindowEdge(id: 1, rect: CGRect(x: 100, y: 200, width: 400, height: 200), visible: [100...500])

    private func scene(reduceMotion: Bool = false) -> SeasonScene {
        let scene = SeasonScene(size: CGSize(width: 1000, height: 800), screenOrigin: .zero, season: Snow())
        scene.reduceMotion = reduceMotion
        return scene
    }

    /// Una scena con la finestra coperta di neve alta 10 pt.
    private func snowyScene(reduceMotion: Bool = false) throws -> SeasonScene {
        let scene = scene(reduceMotion: reduceMotion)
        scene.updateWindows([window], dock: nil, ceiling: 780)
        let pile = try #require(scene.pile(for: window.id))
        for x in stride(from: 101.0, to: 500, by: 2) { pile.add(atX: x, radius: 1, growth: 10) }
        return scene
    }

    private func snow(_ scene: SeasonScene) -> CGFloat {
        scene.pile(for: window.id)?.heights.reduce(0, +) ?? 0
    }

    private func run(_ scene: SeasonScene, from start: TimeInterval = 0, seconds: TimeInterval = 2) {
        for i in 0...Int(seconds * 60) { scene.step(at: start + TimeInterval(i) / 60) }
    }

    private var snowballs: (SeasonScene) -> [Snowball] = { $0.toys.compactMap { $0 as? Snowball } }
    private var snowmen: (SeasonScene) -> [Snowman] = { $0.toys.compactMap { $0 as? Snowman } }

    // MARK: - Palle di neve

    @Test func rollingThroughSettledSnowMakesASnowball() throws {
        let scene = try snowyScene()
        for x in stride(from: 110.0, through: 490, by: 10) { scene.roll(at: CGPoint(x: x, y: 404)) }
        #expect(!snowballs(scene).isEmpty)
        #expect(snow(scene) < 400 * 10 / 2 * 0.2, "la neve raccolta sparisce dalla finestra")
    }

    @Test func rollingWhereThereIsNoSnowMakesNothing() {
        let scene = scene()
        scene.updateWindows([window], dock: nil, ceiling: 780)
        for x in stride(from: 110.0, through: 490, by: 10) { scene.roll(at: CGPoint(x: x, y: 404)) }
        #expect(snowballs(scene).isEmpty)
    }

    @Test func sweepingBackAndForthWithOptionDoesNotShakeTheGlobe() throws {
        let scene = try snowyScene()
        // Il caso del QA (SBU-60): passate avanti e indietro tra 200 e 260 a 60 fps, con ⌥.
        var time: TimeInterval = 0
        for pass in 0..<6 {
            for step in 0...15 {
                let x = pass % 2 == 0 ? 200 + Double(step) * 4 : 260 - Double(step) * 4
                let point = CGPoint(x: x, y: 404)
                scene.pointerMoved(to: point, time: time, rolling: true)
                scene.roll(at: point)
                time += 1.0 / 60
            }
        }
        #expect(snow(scene) > 2000, "la neve fuori dalle passate resta sulla finestra")
        #expect(scene.grainCount == 0)
    }

    @Test func gatheredSnowIsForgottenWhenTheSeasonChanges() throws {
        let scene = try snowyScene()
        for x in stride(from: 110.0, through: 160, by: 10) { scene.roll(at: CGPoint(x: x, y: 404)) }
        #expect(snowballs(scene).isEmpty)
        scene.setSeason(Summer())
        scene.setSeason(Snow())
        scene.updateWindows([window], dock: nil, ceiling: 780)
        let pile = try #require(scene.pile(for: window.id))
        for x in stride(from: 101.0, to: 500, by: 2) { pile.add(atX: x, radius: 1, growth: 10) }
        for x in stride(from: 300.0, through: 340, by: 10) { scene.roll(at: CGPoint(x: x, y: 404)) }
        #expect(snowballs(scene).isEmpty, "la neve raccolta prima non conta più")
    }

    @Test func onlyWinterMakesSnowballs() throws {
        let scene = try snowyScene()
        scene.setSeason(Summer())
        for x in stride(from: 110.0, through: 490, by: 10) { scene.roll(at: CGPoint(x: x, y: 404)) }
        #expect(snowballs(scene).isEmpty)
    }

    @Test func thereIsALimitToSnowballs() {
        let scene = scene()
        for i in 0..<(Tuning.maxSnowballs + 5) { scene.makeSnowball(at: CGPoint(x: 40 * i + 20, y: 0)) }
        #expect(snowballs(scene).count == Tuning.maxSnowballs)
    }

    @Test func aThrownSnowballRollsAlongTheEdge() {
        let scene = scene()
        let ball = scene.makeSnowball(at: CGPoint(x: 100, y: 0))
        ball.body.release(velocity: CGVector(dx: 400, dy: 0))
        run(scene, seconds: 0.5)
        #expect(ball.body.position.x > 250, "rotola più lontano di un oggetto qualunque")
        #expect(ball.spin != 0, "e gira mentre rotola")
    }

    @Test func clearingTakesTheLooseSnowballsButNotTheSnowmen() {
        let scene = scene()
        scene.makeSnowball(at: CGPoint(x: 100, y: 0))
        scene.add(Snowman(at: CGPoint(x: 600, y: 0)))
        scene.clearSnowballs()
        #expect(snowballs(scene).isEmpty)
        #expect(snowmen(scene).count == 1)
    }

    @Test func meltingTakesSnowballsAndSnowmen() {
        let scene = scene()
        scene.makeSnowball(at: CGPoint(x: 100, y: 0))
        scene.add(Snowman(at: CGPoint(x: 600, y: 0)))
        scene.meltAll()
        #expect(scene.toys.isEmpty)
    }

    // MARK: - Pupazzo

    @Test func threeSnowballsTogetherBecomeASnowman() {
        let scene = scene()
        for x in [300.0, 315, 330] { scene.makeSnowball(at: CGPoint(x: x, y: 0)) }
        scene.makeSnowball(at: CGPoint(x: 800, y: 0))
        run(scene, seconds: 0.2)
        #expect(snowmen(scene).count == 1)
        #expect(snowballs(scene).count == 1, "quella lontana resta una palla")
        #expect(abs((snowmen(scene).first?.body.position.x ?? 0) - 315) < 1)
    }

    @Test func twoSnowballsTogetherStayBalls() {
        let scene = scene()
        for x in [300.0, 315] { scene.makeSnowball(at: CGPoint(x: x, y: 0)) }
        run(scene, seconds: 0.2)
        #expect(snowmen(scene).isEmpty)
    }

    @Test func aSnowballInHandDoesNotJoinASnowman() {
        let scene = scene()
        for x in [300.0, 315, 330] { scene.makeSnowball(at: CGPoint(x: x, y: 0)) }
        #expect(scene.grab(at: CGPoint(x: 330, y: 9), time: 0))
        run(scene, seconds: 0.2)
        #expect(snowmen(scene).isEmpty)
    }

    @Test func aSnowmanDoesNotStandWhereItWouldCoverTheMenuBar() {
        let scene = scene()
        // Finestra ingrandita: non prende neve (SBU-101), il pupazzo non ci si ferma.
        let maximized = WindowEdge(id: 2, rect: CGRect(x: 0, y: 0, width: 1000, height: 780), visible: [0...1000])
        scene.updateWindows([maximized], dock: nil, ceiling: 780)
        let snowman = Snowman(at: CGPoint(x: 500, y: 790))
        scene.add(snowman)
        run(scene)
        #expect(snowman.body.position.y == 0, "cade fino in fondo")
    }

    @Test(arguments: [
        ([CGPoint(x: 0, y: 0), CGPoint(x: 20, y: 0), CGPoint(x: 40, y: 0)], [0, 1, 2] as [Int]?),
        ([CGPoint(x: 0, y: 0), CGPoint(x: 200, y: 0), CGPoint(x: 20, y: 0), CGPoint(x: 10, y: 10)], [0, 2, 3]),
        ([CGPoint(x: 0, y: 0), CGPoint(x: 30, y: 0), CGPoint(x: 60, y: 0)], nil),
        ([CGPoint(x: 0, y: 0), CGPoint(x: 1, y: 0)], nil),
    ])
    func theSnowmanNeedsThreeBallsCloseToEachOther(_ balls: [CGPoint], _ trio: [Int]?) {
        #expect(snowmanTrio(balls, within: 40) == trio)
    }

    // MARK: - Neve che scivola via

    @Test func aWindowMovedSlowlyKeepsItsSnow() throws {
        let scene = try snowyScene()
        let before = snow(scene)
        let moved = WindowEdge(id: 1, rect: window.rect.offsetBy(dx: 15, dy: -10), visible: [115...515])
        scene.updateWindows([moved], dock: nil, ceiling: 780)
        #expect(abs(snow(scene) - before) < 1)
        #expect(scene.grainCount == 0)
    }

    @Test func aWindowMovedFastLosesItsSnow() throws {
        let scene = try snowyScene()
        let moved = WindowEdge(id: 1, rect: window.rect.offsetBy(dx: 200, dy: 0), visible: [300...700])
        scene.updateWindows([moved], dock: nil, ceiling: 780)
        #expect(snow(scene) == 0)
        #expect(scene.grainCount > 0, "scivola giù come polvere")
    }

    @Test func aResizedWindowLosesItsSnow() throws {
        let scene = try snowyScene()
        let resized = WindowEdge(id: 1, rect: CGRect(x: 100, y: 200, width: 300, height: 200), visible: [100...400])
        scene.updateWindows([resized], dock: nil, ceiling: 780)
        #expect(snow(scene) == 0)
    }

    // MARK: - Palla di vetro

    @Test func shakingTheGlobeLiftsAllTheSnow() throws {
        let scene = try snowyScene()
        scene.shakeGlobe()
        #expect(snow(scene) == 0)
        #expect(scene.grainCount > 0)
        run(scene, seconds: 0.3)
        #expect(scene.highestGrain > 450, "la neve sale sopra la finestra")
    }

    @Test func aShakenWindowShakesTheGlobe() throws {
        let scene = try snowyScene()
        scene.windowsShaken([7])
        #expect(snow(scene) == 0)
    }

    @Test func aShakenPointerShakesTheGlobe() throws {
        let scene = try snowyScene()
        for i in 0..<12 { scene.pointerMoved(to: CGPoint(x: i % 2 == 0 ? 600 : 700, y: 600), time: Double(i) * 0.08) }
        #expect(snow(scene) == 0)
    }

    @Test func theGlobeRestsBetweenShakes() throws {
        let scene = try snowyScene()
        scene.shakeGlobe()
        let pile = try #require(scene.pile(for: window.id))
        pile.add(atX: 300, radius: 1, growth: 10)
        scene.shakeGlobe()
        #expect(snow(scene) > 0, "subito dopo una scossa la seconda non conta")
    }

    @Test func withReduceMotionTheGlobeStaysStill() throws {
        let scene = try snowyScene(reduceMotion: true)
        scene.shakeGlobe()
        #expect(snow(scene) > 0)
        #expect(scene.grainCount == 0)
    }
}
