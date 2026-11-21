import CoreGraphics
import Foundation
import Testing
@testable import SbuSeasons

/// Impostazioni → Visitatori (SBU-187): chi passa da solo (Babbo Natale, Yeti, trenino, elfi) e quanto spesso.
/// E gli elfi, che escono dalla neve, rotolano tre palle e fanno un pupazzo.
@MainActor
struct VisitorChoiceTests {
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Rome")!
        return calendar
    }()

    private func scene(on day: DateComponents = DateComponents(year: 2026, month: 12, day: 10, hour: 12),
                       reduceMotion: Bool = false) -> SeasonScene {
        let scene = SeasonScene(size: CGSize(width: 1000, height: 800), screenOrigin: .zero, season: Snow())
        scene.reduceMotion = reduceMotion
        let date = Self.calendar.date(from: day)!
        let diary = GiftDiary(defaults: UserDefaults(suiteName: "VisitorChoiceTests-\(UUID().uuidString)")!, calendar: Self.calendar)
        scene.christmas = ChristmasClock(now: { date }, calendar: Self.calendar, diary: diary)
        return scene
    }

    private func run(_ scene: SeasonScene, from start: TimeInterval = 0, seconds: TimeInterval) {
        for i in 0...Int(seconds * 60) { scene.step(at: start + TimeInterval(i) / 60) }
    }

    // MARK: - Frequenza

    @Test func oftenHalvesTheWaitAndRarelyDoublesIt() {
        let range: ClosedRange<CGFloat> = 100...200
        #expect(VisitFrequency.often.scaled(range) == 50...100)
        #expect(VisitFrequency.sometimes.scaled(range) == range)
        #expect(VisitFrequency.rarely.scaled(range) == 200...400)
    }

    @Test func theTrainComesSoonerWhenOften() {
        let scene = scene()
        let visitors = Visitors(random: { 0 })
        visitors.passesAlone = { $0 == .train }
        visitors.frequency = { .often }
        visitors.scenes = [scene]
        visitors.tick(at: 0)
        visitors.tick(at: TimeInterval(Tuning.trainInterval.lowerBound / 2) + 1)
        #expect(scene.train != nil)
    }

    @Test func theTrainWaitsLongerWhenRarely() {
        let scene = scene()
        let visitors = Visitors(random: { 0 })
        visitors.passesAlone = { $0 == .train }
        visitors.frequency = { .rarely }
        visitors.scenes = [scene]
        visitors.tick(at: 0)
        visitors.tick(at: TimeInterval(Tuning.trainInterval.lowerBound) + 1)
        #expect(scene.train == nil)
    }

    // MARK: - Babbo Natale

    @Test func santaSwitchedOffDoesNotComeAloneAtChristmas() {
        let scene = scene()
        let passages = Passages(random: { 0 })
        passages.passesAlone = { false }
        passages.scenes = [scene]
        passages.tick(at: 0)
        passages.tick(at: 10_000)
        #expect(scene.santa == nil)
        #expect(passages.send(at: 10_001), "dal menu passa sempre")
    }

    @Test func santaSwitchedOnComesAloneAtChristmas() {
        let scene = scene()
        let passages = Passages(random: { 0 })
        passages.passesAlone = { true }
        passages.scenes = [scene]
        passages.tick(at: 0)
        passages.tick(at: 10_000)
        #expect(scene.santa != nil)
    }

    // MARK: - Elfi

    @Test func elvesComeAloneWhenSwitchedOn() {
        let scene = scene()
        let visitors = Visitors(random: { 0 })
        visitors.passesAlone = { $0 == .elves }
        visitors.scenes = [scene]
        visitors.tick(at: 0)
        visitors.tick(at: TimeInterval(Tuning.elvesInterval.lowerBound) + 1)
        #expect(scene.elf != nil)
    }

    @Test func theElfRollsThreeBallsIntoASnowmanAndLeaves() throws {
        let scene = scene()
        var exit: (VisitorKind, VisitorExit)?
        scene.onVisitorLeft = { exit = ($0, $1) }
        try #require(scene.sendElf(heading: 1, at: 400) != nil)
        run(scene, seconds: Double(Tuning.elfRollInterval) * 4 + 1)
        #expect(scene.toys.contains { $0 is Snowman }, "il pupazzo che fanno resta")
        run(scene, from: 20, seconds: 12)
        #expect(scene.elf == nil)
        #expect(exit?.0 == .elves)
        #expect(scene.toys.contains { $0 is Snowman })
    }

    @Test func withReduceMotionTheElfStillMakesTheSnowman() throws {
        let scene = scene(reduceMotion: true)
        try #require(scene.sendElf(heading: -1, at: 500) != nil)
        run(scene, seconds: Double(Tuning.elfRollInterval) * 4 + 1)
        #expect(scene.toys.contains { $0 is Snowman })
    }

    @Test func pausingTakesTheElfAway() throws {
        let scene = scene()
        try #require(scene.sendElf(heading: 1, at: 400) != nil)
        scene.toysPaused = true
        #expect(scene.elf == nil)
    }

    @Test func theElfVisitsOnlyOneScreen() {
        let left = SeasonScene(size: CGSize(width: 1000, height: 800), screenOrigin: .zero, season: Snow())
        let right = SeasonScene(size: CGSize(width: 1000, height: 800), screenOrigin: CGPoint(x: 1000, y: 0), season: Snow())
        let visitors = Visitors(random: { 0.75 })
        visitors.scenes = [left, right]
        #expect(visitors.send(.elves))
        #expect([left, right].filter { $0.elf != nil }.count == 1)
    }
}
