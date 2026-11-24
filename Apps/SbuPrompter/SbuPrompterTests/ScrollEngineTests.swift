import Testing
@testable import SbuPrompter

struct ScrollEngineTests {
    @Test func advancesBySpeedTimesTime() {
        var engine = ScrollEngine(speed: 40, maxOffset: 1000)
        engine.advance(by: 0.5)
        #expect(engine.offset == 20)
    }

    @Test func stopsAtTheEnd() {
        var engine = ScrollEngine(speed: 100, maxOffset: 50)
        engine.advance(by: 2)
        #expect(engine.offset == 50)
        #expect(engine.isAtEnd)
    }

    @Test func manualScrollIsClampedBothWays() {
        var engine = ScrollEngine(speed: 40, maxOffset: 100)
        engine.scroll(by: -30)
        #expect(engine.offset == 0)
        engine.scroll(by: 500)
        #expect(engine.offset == 100)
    }

    @Test func rewindGoesBackToTheTop() {
        var engine = ScrollEngine(speed: 40, maxOffset: 100)
        engine.scroll(by: 60)
        engine.rewind()
        #expect(engine.offset == 0)
    }

    @Test func fasterAndSlowerStayInRange() {
        var engine = ScrollEngine(speed: ScrollEngine.speedRange.upperBound, maxOffset: 100)
        engine.faster()
        #expect(engine.speed == ScrollEngine.speedRange.upperBound)
        engine.speed = ScrollEngine.speedRange.lowerBound
        engine.slower()
        #expect(engine.speed == ScrollEngine.speedRange.lowerBound)
        engine.faster()
        #expect(engine.speed == ScrollEngine.speedSteps[1])
    }

    @Test(arguments: [(40.0, 50.0, 35.0), (43, 50, 40), (4, 6, 4), (5, 6, 4)])
    func fasterAndSlowerSnapToTheNextStep(start: Double, faster: Double, slower: Double) {
        var up = ScrollEngine(speed: start, maxOffset: 100)
        up.faster()
        #expect(up.speed == faster)
        var down = ScrollEngine(speed: start, maxOffset: 100)
        down.slower()
        #expect(down.speed == slower)
    }

    @Test func slowestSpeedIsFourPointsASecond() {
        #expect(ScrollEngine.speedRange.lowerBound == 4)
        #expect(ScrollEngine.speedSteps == ScrollEngine.speedSteps.sorted())
    }

    @Test func settingSpeedClamps() {
        var engine = ScrollEngine(speed: 40, maxOffset: 100)
        engine.speed = 10_000
        #expect(engine.speed == ScrollEngine.speedRange.upperBound)
    }

    @Test func shrinkingContentPullsTheOffsetBack() {
        var engine = ScrollEngine(speed: 40, maxOffset: 100)
        engine.scroll(by: 90)
        engine.maxOffset = 30
        #expect(engine.offset == 30)
    }

    @Test func approachEasesTowardATarget() {
        var engine = ScrollEngine(speed: 40, maxOffset: 1000)
        engine.approach(200, by: 0.1)
        #expect(engine.offset > 0 && engine.offset < 200)
        for _ in 0..<200 { engine.approach(200, by: 0.1) }
        #expect(abs(engine.offset - 200) < 0.5)
    }
}
