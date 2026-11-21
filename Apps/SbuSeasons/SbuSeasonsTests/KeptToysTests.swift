import CoreGraphics
import Foundation
import Testing
@testable import SbuSeasons

/// Alberi, decorazioni e pupazzi restano dove sono (SBU-178): si salvano e tornano uguali, sullo stesso schermo;
/// se lo schermo non c'è più, su quello principale.
@MainActor
struct KeptToysTests {
    private func scene(width: CGFloat = 1000, season: any Season = Snow()) -> SeasonScene {
        SeasonScene(size: CGSize(width: width, height: 800), screenOrigin: .zero, season: season)
    }

    private func decoratedScene() -> SeasonScene {
        let scene = scene()
        let tree = ChristmasTree(at: CGPoint(x: 300, y: 0))
        tree.look.hanging = .lights
        tree.look.hang(at: CGPoint(x: 0, y: 30))
        tree.look.grow(by: 1.5)
        scene.add(tree)
        var look = SnowmanLook()
        look.hat = .topHat
        scene.add(Snowman(at: CGPoint(x: 700, y: 60), look: look))
        scene.makeSnowball(at: CGPoint(x: 100, y: 0))
        return scene
    }

    @Test func treesDecorationsAndSnowmenComeBackTheSame() {
        let kept = decoratedScene().keptToys(screen: "A")
        #expect(kept.trees.count == 1 && kept.snowmen.count == 1, "le palle sciolte non si salvano")
        let fresh = scene()
        fresh.restore(kept)
        let tree = fresh.toys.compactMap { $0 as? ChristmasTree }.first
        let snowman = fresh.toys.compactMap { $0 as? Snowman }.first
        #expect(tree?.body.position == CGPoint(x: 300, y: 0))
        #expect(tree?.look == kept.trees[0].look)
        #expect(tree?.look.growth == 1.5)
        #expect(snowman?.body.position == CGPoint(x: 700, y: 60))
        #expect(snowman?.look.hat == .topHat)
    }

    @Test func theyAreRestoredOnTheirScreenOrOnTheMainOne() {
        let screens = ["main", "side"]
        #expect(KeptToys.screenIndex(for: "side", among: screens) == 1)
        #expect(KeptToys.screenIndex(for: "gone", among: screens) == 0)
    }

    @Test func eachScreenGetsOnlyItsOwnToys() {
        var kept = decoratedScene().keptToys(screen: "side")
        kept.snowmen.append(KeptToys.Snowman(screen: "gone", position: CGPoint(x: 10, y: 0), look: SnowmanLook()))
        let main = scene()
        let side = scene()
        kept.restore(into: [("main", main), ("side", side)])
        #expect(side.toys.count == 2)
        #expect(main.toys.count == 1, "quello dello schermo scollegato va sul principale")
    }

    @Test func onASmallerScreenTheyStayInside() {
        let kept = decoratedScene().keptToys(screen: "A")
        let small = scene(width: 500)
        small.restore(kept)
        #expect(small.toys.allSatisfy { $0.body.position.x <= 500 })
    }

    @Test func outsideWinterNothingComesBack() {
        let summer = scene(season: Summer())
        summer.restore(decoratedScene().keptToys(screen: "A"))
        #expect(summer.toys.isEmpty)
    }

    @Test func theKeeperSavesOnlyWhatChangedAndReadsItBack() throws {
        let defaults = try #require(UserDefaults(suiteName: "SbuSeasonsTests.KeptToys"))
        defaults.removePersistentDomain(forName: "SbuSeasonsTests.KeptToys")
        let keeper = ToyKeeper(defaults: defaults)
        #expect(keeper.load() == KeptToys())
        let kept = decoratedScene().keptToys(screen: "A")
        #expect(keeper.save(kept))
        #expect(!keeper.save(kept), "uguale a prima: non riscrive")
        #expect(ToyKeeper(defaults: defaults).load() == kept)
    }
}
