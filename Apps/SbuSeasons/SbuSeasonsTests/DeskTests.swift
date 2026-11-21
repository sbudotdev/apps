import CoreGraphics
import Foundation
import Testing
@testable import SbuSeasons

/// «Decora» (SBU-187): decorazioni libere sulla scrivania. Si spostano, si ingrandiscono, si girano; le luci hanno
/// due estremità libere e il centro che pende. Restano al riavvio, tutto l'anno, al massimo `Tuning.maxDeskItems` per schermo.
@MainActor
struct DeskTests {
    private func lights(from start: CGPoint = CGPoint(x: 100, y: 500), to end: CGPoint = CGPoint(x: 300, y: 500)) -> DeskItem {
        DeskItem(kind: .lights, screen: "A", start: start, end: end)
    }

    // MARK: - Luci

    @Test func theMiddleOfTheLightsHangsDown() {
        let points = lights().wire
        let middle = points[points.count / 2]
        #expect(points.first == CGPoint(x: 100, y: 500) && points.last == CGPoint(x: 300, y: 500))
        #expect(middle.y < 500 - 20, "pende")
        #expect(abs(middle.x - 200) < 1)
    }

    @Test func movingOneEndLeavesTheOtherWhereItIs() {
        var item = lights()
        item.moveEnd(1, to: CGPoint(x: 400, y: 600))
        #expect(item.start == CGPoint(x: 100, y: 500))
        #expect(item.end == CGPoint(x: 400, y: 600))
    }

    @Test func theNearestEndIsTheOneYouGrab() {
        let item = lights()
        #expect(item.end(near: CGPoint(x: 104, y: 498)) == 0)
        #expect(item.end(near: CGPoint(x: 297, y: 503)) == 1)
        #expect(item.end(near: CGPoint(x: 200, y: 470)) == nil, "in mezzo si sposta tutto il filo")
    }

    @Test func theFrameHoldsTheWholeWireAndTheBulbs() {
        let item = lights()
        let frame = item.frame
        for point in item.wire { #expect(frame.insetBy(dx: 4, dy: 4).contains(point)) }
    }

    @Test func draggingTheLightsMovesBothEnds() {
        var item = lights()
        item.move(by: CGVector(dx: 10, dy: -20))
        #expect(item.start == CGPoint(x: 110, y: 480) && item.end == CGPoint(x: 310, y: 480))
    }

    // MARK: - Le altre

    @Test(arguments: DeskItem.Kind.allCases.filter { $0 != .lights })
    func anItemIsCenteredWhereYouPutIt(_ kind: DeskItem.Kind) {
        let item = DeskItem(kind: kind, screen: "A", center: CGPoint(x: 400, y: 300))
        #expect(abs(item.frame.midX - 400) < 0.001 && abs(item.frame.midY - 300) < 0.001)
        #expect(item.frame.width > 10 && item.frame.height > 10)
    }

    @Test func resizingStopsAtTheLimits() {
        var item = DeskItem(kind: .penguin, screen: "A", center: .zero)
        item.resize(by: 100)
        #expect(item.scale == Tuning.deskScale.upperBound)
        item.resize(by: 0.0001)
        #expect(item.scale == Tuning.deskScale.lowerBound)
    }

    @Test func aTurnedItemNeedsAWiderFrame() {
        var item = DeskItem(kind: .candle, screen: "A", center: .zero)
        let upright = item.frame
        item.turn(by: .pi / 2)
        #expect(item.frame.width > upright.width)
        #expect(abs(item.frame.width - upright.height) < 0.5, "di traverso è larga quanto era alta")
    }

    @Test func turningGoesRoundAndComesBack() {
        var item = DeskItem(kind: .stocking, screen: "A", center: .zero)
        for _ in 0..<8 { item.turn(by: .pi / 2) }
        #expect(abs(item.rotation) < 0.0001)
    }

    // MARK: - Quante

    @Test func eachScreenHoldsAtMostTheLimitTheOldestGoes() {
        var items: [DeskItem] = []
        for i in 0..<(Tuning.maxDeskItems + 2) {
            items = DeskItem.adding(DeskItem(kind: .candle, screen: "A", center: CGPoint(x: CGFloat(i), y: 0)), to: items)
        }
        items = DeskItem.adding(DeskItem(kind: .penguin, screen: "B", center: .zero), to: items)
        #expect(items.filter { $0.screen == "A" }.count == Tuning.maxDeskItems)
        #expect(items.first { $0.screen == "A" }?.center.x == 2, "via le più vecchie")
        #expect(items.filter { $0.screen == "B" }.count == 1, "l'altro schermo ha il suo limite")
    }

    // MARK: - Salvataggio

    @Test func theDeskIsSavedWithTheTreesAndSnowmen() throws {
        var kept = KeptToys()
        kept.desk = [lights(), DeskItem(kind: .bonfire, screen: "B", center: CGPoint(x: 50, y: 60), scale: 1.5, rotation: 0.3)]
        let back = try JSONDecoder().decode(KeptToys.self, from: JSONEncoder().encode(kept))
        #expect(back == kept)
    }

    @Test func aSaveFromBeforeTheDeskStillOpens() throws {
        let old = #"{"trees":[],"snowmen":[{"screen":"A","position":[10,0],"look":{"balls":["medium","medium","medium"],"hat":"none","scarf":"none","nose":"carrot","buttons":true}}]}"#
        let kept = try JSONDecoder().decode(KeptToys.self, from: Data(old.utf8))
        #expect(kept.snowmen.count == 1)
        #expect(kept.desk.isEmpty)
    }

    @Test func outsideWinterTheDeskStaysButSnowmenMelt() {
        var kept = KeptToys()
        kept.desk = [lights()]
        kept.snowmen = [KeptToys.Snowman(screen: "A", position: .zero, look: SnowmanLook())]
        let summer = SeasonScene(size: CGSize(width: 1000, height: 800), screenOrigin: .zero, season: Summer())
        summer.restore(kept)
        #expect(summer.toys.isEmpty)
        #expect(kept.only { $0 == "A" }.desk.count == 1, "le decorazioni non dipendono dalla stagione")
    }

    @Test func anItemFromAScreenThatIsGoneMovesInsideTheMainOne() {
        let item = DeskItem(kind: .penguin, screen: "gone", center: CGPoint(x: 3000, y: 2000))
        let placed = item.placed(on: "main", size: CGSize(width: 1440, height: 900))
        #expect(placed.screen == "main")
        #expect(CGRect(x: 0, y: 0, width: 1440, height: 900).contains(placed.center))
        let lights = lights(from: CGPoint(x: 1400, y: 500), to: CGPoint(x: 1700, y: 500))
            .placed(on: "main", size: CGSize(width: 1440, height: 900))
        #expect(lights.end.x <= 1440 && lights.start.x < lights.end.x, "il filo resta intero, spostato dentro")
    }
}
