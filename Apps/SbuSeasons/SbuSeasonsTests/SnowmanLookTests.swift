import CoreGraphics
import Foundation
import Testing
@testable import SbuSeasons

/// Il pupazzo da vestire (SBU-178): la taglia delle tre palle e i vestiti, scelti dalla sua scheda.
@MainActor
struct SnowmanLookTests {
    @Test func theFirstSnowmanLooksLikeTheOldOne() {
        let look = SnowmanLook()
        #expect(look.balls == [.medium, .medium, .medium])
        #expect(look.nose == .carrot)
        #expect(look.buttons)
        #expect(look.hat == .none && look.scarf == .none)
    }

    @Test func biggerBallsMakeATallerAndWiderSnowman() {
        var big = SnowmanLook()
        big.balls = [.large, .large, .large]
        var small = SnowmanLook()
        small.balls = [.small, .small, .small]
        #expect(big.size.height > SnowmanLook().size.height)
        #expect(small.size.height < SnowmanLook().size.height)
        #expect(big.size.width > small.size.width)
    }

    @Test(arguments: [SnowmanLook.Hat.topHat, .beanie])
    func aHatMakesItTaller(_ hat: SnowmanLook.Hat) {
        var look = SnowmanLook()
        look.hat = hat
        #expect(look.size.height > SnowmanLook().size.height)
    }

    @Test func theBallsAreStackedFromTheBottom() {
        let balls = SnowmanLook().ballFrames
        #expect(balls[0].minY == 0)
        #expect(balls[1].minY > balls[0].minY && balls[1].minY < balls[0].maxY, "si toccano")
        #expect(balls[2].minY > balls[1].minY && balls[2].minY < balls[1].maxY)
    }

    @Test func aLookSurvivesTheTripToJSON() throws {
        var look = SnowmanLook()
        look.balls = [.large, .small, .medium]
        look.hat = .beanie
        look.scarf = .green
        look.nose = .coal
        look.buttons = false
        #expect(try JSONDecoder().decode(SnowmanLook.self, from: JSONEncoder().encode(look)) == look)
    }

    @Test func dressingTheSnowmanRedrawsIt() {
        let snowman = Snowman(at: .zero)
        let height = snowman.node.size.height
        snowman.look.hat = .topHat
        #expect(snowman.node.size.height > height)
    }

    @Test func aClickOnTheSnowmanOpensItsCard() {
        let scene = SeasonScene(size: CGSize(width: 1000, height: 800), screenOrigin: CGPoint(x: 100, y: 0), season: Snow())
        let snowman = Snowman(at: CGPoint(x: 500, y: 0))
        scene.add(snowman)
        var opened: (Toy, CGPoint)?
        scene.onCard = { opened = ($0, $1) }
        scene.grab(at: CGPoint(x: 500, y: 20), time: 0)
        scene.letGo(at: CGPoint(x: 500, y: 20), time: 0.05)
        #expect(opened?.0 === snowman)
        #expect(opened?.1 == CGPoint(x: 600, y: snowman.node.size.height), "sopra la testa, in coordinate globali")
    }
}
