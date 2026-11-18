import AppKit
import Testing
@testable import SbuSeasons

/// I passaggi (Babbo Natale): la pausa dei giochi, il ritorno a intervalli casuali, il percorso su più schermi (SBU-114).
@MainActor
struct PassagesTests {
    nonisolated private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Rome")!
        return calendar
    }()

    nonisolated private static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    private let size = CGSize(width: 1000, height: 800)

    private func scene(at origin: CGPoint = .zero, on date: Date = date(2026, 11, 18), reduceMotion: Bool = false) -> SeasonScene {
        let scene = SeasonScene(size: size, screenOrigin: origin, season: Snow())
        scene.reduceMotion = reduceMotion
        let diary = GiftDiary(defaults: UserDefaults(suiteName: "PassagesTests-\(UUID().uuidString)")!, calendar: Self.calendar)
        scene.christmas = ChristmasClock(now: { date }, calendar: Self.calendar, diary: diary)
        return scene
    }

    /// `roll` sempre uguale: 0.5 o più = verso destra, e gli intervalli a metà.
    private func passages(_ scenes: [SeasonScene], roll: Double = 0.75) -> Passages {
        let passages = Passages(random: { roll })
        passages.scenes = scenes
        return passages
    }

    /// Fa girare le scene e l'orologio dei passaggi da `start` a `end` secondi, 60 passi al secondo.
    private func run(_ passages: Passages, from start: TimeInterval = 0, to end: TimeInterval, each: (() -> Void)? = nil) {
        for i in Int(start * 60)...Int(end * 60) {
            let now = TimeInterval(i) / 60
            passages.scenes.forEach { $0.step(at: now) }
            passages.tick(at: now)
            each?()
        }
    }

    private func visits(_ passages: Passages) -> Int { passages.scenes.map(\.santaVisits).reduce(0, +) }

    // MARK: - Ferma tutti i giochi

    @Test func pausingTakesAwaySantaInFlight() throws {
        let scene = scene()
        try #require(scene.sendSanta() != nil)
        scene.toysPaused = true
        #expect(scene.santa == nil, "in pausa la slitta non resta ferma in cielo")
        #expect(scene.sendSanta() == nil, "e non ne parte un'altra")
    }

    @Test func whilePausedNothingPassesUntilResumed() {
        let passages = passages([scene(on: Self.date(2026, 12, 24))])
        #expect(passages.send(at: 0))
        passages.paused = true
        #expect(!passages.isFlying)
        #expect(!passages.send(at: 1), "dal menu non parte niente")
        run(passages, from: 1, to: 3600)
        #expect(visits(passages) == 1, "in un'ora di pausa, la vigilia, Babbo Natale non è ripassato")
        passages.paused = false
        run(passages, from: 3601, to: 3601 + Double(Tuning.santaLoopInterval.upperBound) + 1)
        #expect(visits(passages) == 2, "tolta la pausa ripassa")
    }

    @Test func thePauseStaysWhenTheScreensChange() {
        let passages = passages([scene()])
        passages.paused = true
        let fresh = scene()
        passages.scenes = [fresh]
        #expect(fresh.toysPaused, "un monitor collegato o il risveglio ricreano le scene: la pausa resta")
    }

    @Test func changingSeasonEndsThePauseAndTheLoop() {
        let passages = passages([scene()])
        passages.send(at: 0)
        passages.paused = true
        passages.seasonChanged()
        #expect(!passages.paused)
        #expect(!passages.looping)
    }

    // MARK: - In loop casuale

    @Test(arguments: [(0.0, 90.0), (0.5, 165.0), (0.999, 239.85)])
    func theDelayIsPickedInsideTheRange(_ roll: Double, _ expected: Double) {
        #expect(abs(Passages.delay(in: 90...240, roll: roll) - expected) < 0.001)
    }

    @Test func calledOnceSantaComesBackByHimselfAtRandomIntervals() {
        let passages = passages([scene()], roll: 0.5)
        passages.send(at: 0)
        let wait = Passages.delay(in: Tuning.santaLoopInterval, roll: 0.5)
        run(passages, from: 0, to: wait - 1)
        #expect(visits(passages) == 1, "prima dell'intervallo no")
        run(passages, from: wait, to: wait + 1)
        #expect(visits(passages) == 2, "poi ripassa da solo, anche a novembre")
        run(passages, from: wait + 1, to: wait * 2 + 1)
        #expect(visits(passages) == 3)
    }

    @Test func withoutBeingCalledSantaComesOnlyAtChristmasTime() {
        let december = passages([scene(on: Self.date(2026, 12, 10))])
        let november = passages([scene(on: Self.date(2026, 11, 17))])
        let late = Double(Tuning.santaFirstVisit.upperBound) + 1
        run(december, to: late)
        run(november, to: late)
        #expect(visits(december) == 1)
        #expect(visits(november) == 0)
    }

    @Test func withReduceMotionTheLoopGoesOnWithoutTheSleighCrossing() {
        let scene = scene(reduceMotion: true)
        let passages = passages([scene], roll: 0)
        passages.send(at: 0)
        #expect(scene.santa == nil, "niente slitta che attraversa lo schermo")
        run(passages, to: Double(Tuning.santaLoopInterval.lowerBound) + 1)
        #expect(scene.santaVisits == 2)
        #expect(scene.santa == nil)
    }

    @Test func outsideWinterNothingPasses() {
        let summer = SeasonScene(size: size, screenOrigin: .zero, season: Summer())
        let passages = passages([summer])
        #expect(!passages.send(at: 0))
    }

    // MARK: - Più schermi

    @Test func santaCrossesEveryScreenOneAfterTheOtherAtTheSameHeight() throws {
        // Il secondo schermo è a destra e più in alto di 200 pt (sfalsato).
        let left = scene(at: .zero)
        let right = scene(at: CGPoint(x: 1000, y: 200))
        let passages = passages([right, left], roll: 0.75)   // verso destra
        passages.send(at: 0)
        #expect(left.santa != nil && right.santa == nil, "parte dallo schermo più a sinistra")
        let height = try #require(left.santa?.altitude)
        var most = 0
        var enteredAt: CGFloat?
        run(passages, to: 20) {
            most = max(most, passages.scenes.filter { $0.santa != nil }.count)
            if enteredAt == nil, let santa = right.santa { enteredAt = santa.altitude }
        }
        #expect(most == 1, "un solo passaggio alla volta")
        #expect(enteredAt == height - 200, "entra nel vicino alla stessa quota globale")
        #expect(left.santaVisits == 1 && right.santaVisits == 1)
        #expect(!passages.isFlying)
    }

    @Test func withOneScreenNothingChanges() {
        let only = scene()
        let passages = passages([only])
        passages.send(at: 0)
        run(passages, to: 12)
        #expect(only.santaVisits == 1)
        #expect(!passages.isFlying)
    }

    // MARK: - Percorso (puro)

    @Test func screensSideBySideAreCrossedInTheirOrder() {
        let frames = [CGRect(x: 1440, y: 0, width: 1920, height: 1080), CGRect(x: 0, y: 0, width: 1440, height: 900)]
        #expect(ScreenRoute.order(frames, heading: 1) == [1, 0])
        #expect(ScreenRoute.order(frames, heading: -1) == [0, 1])
    }

    @Test func stackedScreensAreCrossedFromTheTopDown() {
        let frames = [
            CGRect(x: 0, y: 0, width: 1440, height: 900),        // in basso
            CGRect(x: 1440, y: 0, width: 1440, height: 900),     // a destra
            CGRect(x: 0, y: 900, width: 1440, height: 900),      // sopra
        ]
        #expect(ScreenRoute.order(frames, heading: 1) == [2, 0, 1])
        #expect(ScreenRoute.order(frames, heading: -1) == [1, 2, 0])
    }

    @Test func theSleighKeepsItsHeightWhereTheNextScreenCoversIt() {
        let next = CGRect(x: 1440, y: -300, width: 1920, height: 1080)   // copre da -300 a 780
        #expect(ScreenRoute.entry(700, into: next, margin: 24) == 1000, "quota locale: 700 + 300")
        #expect(ScreenRoute.entry(770, into: next, margin: 24) == nil, "troppo vicino al bordo: vola alla sua quota solita")
        #expect(ScreenRoute.entry(-400, into: next, margin: 24) == nil)
    }
}
