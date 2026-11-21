import AppKit
import SpriteKit
import Testing
@testable import SbuSeasons

/// L'albero da decorare (SBU-178): fino a 3 alberi, cresce, palline, luci, bastoncini e stella;
/// ogni decorazione si sposta, si ridimensiona, si ruota e si toglie; l'albero si sposta e si taglia.
@MainActor
struct TreeTests {
    private let size = CGSize(width: 1000, height: 800)

    private func scene() -> SeasonScene { SeasonScene(size: size, screenOrigin: .zero, season: Snow()) }

    private func run(_ scene: SeasonScene, from start: TimeInterval = 0, seconds: TimeInterval) {
        for i in 0...Int(seconds * 60) { scene.step(at: start + TimeInterval(i) / 60) }
    }

    // MARK: - Il modello

    @Test func aClickOnABranchHangsTheChosenDecorationThere() {
        var look = TreeLook()
        look.hanging = .candyCane
        let hung = look.hang(at: CGPoint(x: -5, y: 30))
        #expect(hung)
        #expect(look.decorations.map(\.kind) == [.candyCane])
        #expect(look.decorations[0].position == CGPoint(x: -5, y: 30))
    }

    @Test(arguments: [CGPoint(x: 0, y: 3), CGPoint(x: 27, y: 70), CGPoint(x: 0, y: 90)])
    func offTheBranchesNothingIsHung(_ point: CGPoint) {
        var look = TreeLook()
        let hung = look.hang(at: point)
        #expect(!hung)
        #expect(look.decorations.isEmpty)
    }

    @Test func theStarAlwaysGoesOnTheTipAndThereIsOnlyOne() {
        var look = TreeLook()
        look.hanging = .star
        look.hang(at: CGPoint(x: 0, y: 30))
        look.hang(at: CGPoint(x: 5, y: 50))
        #expect(look.decorations.filter { $0.kind == .star }.count == 1)
        #expect(look.decorations[0].position == TreeLook.tip)
    }

    @Test func baublesTakeTheColoursInTurn() {
        var look = TreeLook()
        look.hang(at: CGPoint(x: 0, y: 30))
        look.hang(at: CGPoint(x: 0, y: 40))
        #expect(look.decorations[0].color != look.decorations[1].color)
    }

    @Test func aTreeHoldsAtMostSoManyDecorations() {
        var look = TreeLook()
        for _ in 0..<Tuning.maxDecorations + 5 { look.hang(at: CGPoint(x: 0, y: 40)) }
        #expect(look.decorations.count == Tuning.maxDecorations)
    }

    @Test func aDecorationIsFoundUnderThePointer() {
        var look = TreeLook()
        look.hang(at: CGPoint(x: -8, y: 24))
        look.hang(at: CGPoint(x: 6, y: 50))
        #expect(look.decoration(at: CGPoint(x: 7, y: 51)) == 1)
        #expect(look.decoration(at: CGPoint(x: -8, y: 50)) == nil)
    }

    @Test func aDecorationMovedOnTheBranchesStaysAndOffTheTreeIsTakenAway() {
        var look = TreeLook()
        look.hang(at: CGPoint(x: 0, y: 30))
        look.hang(at: CGPoint(x: 0, y: 40))
        look.drop(0, at: CGPoint(x: 4, y: 55))
        #expect(look.decorations[0].position == CGPoint(x: 4, y: 55))
        look.drop(0, at: CGPoint(x: 60, y: 10))
        #expect(look.decorations.count == 1, "fuori dai rami si toglie")
    }

    @Test func aDecorationGrowsShrinksAndTurnsWithinLimits() {
        var look = TreeLook()
        look.hang(at: CGPoint(x: 0, y: 30))
        look.resize(0, by: 100)
        #expect(look.decorations[0].scale == Tuning.decorationScale.upperBound)
        look.resize(0, by: 0.001)
        #expect(look.decorations[0].scale == Tuning.decorationScale.lowerBound)
        look.turn(0, by: .pi / 4)
        #expect(abs(look.decorations[0].rotation - .pi / 4) < 0.0001)
    }

    @Test func theTreeGrowsTallerWithinLimits() {
        var look = TreeLook()
        look.grow(by: 1.5)
        #expect(look.growth == 1.5)
        look.grow(by: 10)
        #expect(look.growth == Tuning.treeGrowth.upperBound)
        look.grow(by: 0.01)
        #expect(look.growth == Tuning.treeGrowth.lowerBound)
    }

    @Test func aLookSurvivesTheTripToJSON() throws {
        var look = TreeLook()
        look.hanging = .lights
        look.hang(at: CGPoint(x: 0, y: 30))
        look.grow(by: 1.4)
        let data = try JSONEncoder().encode(look)
        #expect(try JSONDecoder().decode(TreeLook.self, from: data) == look)
    }

    // MARK: - Sulla scena

    @Test func thereAreAtMostThreeTrees() {
        let scene = scene()
        for _ in 0..<5 { scene.plantTree() }
        #expect(scene.toys.compactMap { $0 as? ChristmasTree }.count == 3)
    }

    @Test func aGrownTreeIsTallerAndItsDecorationsGrowWithIt() throws {
        let scene = scene()
        let tree = try #require(scene.plantTree())
        let height = tree.frame.height
        tree.clicked(at: CGPoint(x: 0, y: 40))
        tree.resized(at: CGPoint(x: 20, y: 5), by: 1.5)   // sul tronco, fuori dalle decorazioni: cresce l'albero
        #expect(tree.look.growth == 1.5)
        #expect(abs(tree.frame.height - height * 1.5) < 0.01)
        // Un clic sullo stesso punto dell'albero grande cade sulla decorazione di prima.
        #expect(tree.look.decoration(at: CGPoint(x: 0, y: 40)) == 0)
    }

    @Test func pinchingADecorationResizesItNotTheTree() throws {
        let scene = scene()
        let tree = try #require(scene.plantTree())
        tree.clicked(at: CGPoint(x: 0, y: 40))
        tree.resized(at: CGPoint(x: 0, y: 40), by: 2)
        tree.turned(at: CGPoint(x: 0, y: 40), by: 0.5)
        #expect(tree.look.growth == 1)
        #expect(tree.look.decorations[0].scale == 2)
        #expect(tree.look.decorations[0].rotation == 0.5)
    }

    @Test func draggingADecorationMovesItAndNotTheTree() throws {
        let scene = scene()
        let tree = try #require(scene.plantTree())
        run(scene, seconds: 0.2)
        let feet = tree.body.position
        tree.clicked(at: CGPoint(x: 0, y: 30))
        #expect(scene.grab(at: CGPoint(x: feet.x, y: feet.y + 30), time: 1))
        scene.drag(to: CGPoint(x: feet.x + 5, y: feet.y + 50), time: 1.05)
        scene.letGo(at: CGPoint(x: feet.x + 5, y: feet.y + 50), time: 1.1)
        #expect(tree.body.position == feet, "l'albero resta dov'è")
        #expect(tree.look.decorations[0].position == CGPoint(x: 5, y: 50))
    }

    @Test func draggingADecorationOffTheTreeTakesItAway() throws {
        let scene = scene()
        let tree = try #require(scene.plantTree())
        run(scene, seconds: 0.2)
        let feet = tree.body.position
        tree.clicked(at: CGPoint(x: 0, y: 30))
        scene.grab(at: CGPoint(x: feet.x, y: feet.y + 30), time: 1)
        scene.letGo(at: CGPoint(x: feet.x + 120, y: feet.y + 30), time: 1.1)
        #expect(tree.look.decorations.isEmpty)
    }

    @Test func cuttingATreeTakesItAway() throws {
        let scene = scene()
        let tree = try #require(scene.plantTree())
        tree.cut()
        #expect(scene.toys.isEmpty)
    }

    @Test func aSecondaryClickOnATreeAsksForItsCard() throws {
        let scene = scene()
        let tree = try #require(scene.plantTree())
        run(scene, seconds: 0.2)
        var asked: Toy?
        scene.onCard = { toy, _ in asked = toy }
        scene.secondaryClick(at: CGPoint(x: tree.body.position.x, y: 20))
        #expect(asked === tree)
    }
}
