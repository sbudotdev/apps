import AppKit
import SpriteKit
import Testing
@testable import SbuSeasons

/// Natale: le date, il conto alla rovescia, un regalo al giorno, Babbo Natale, l'omino di pan di zenzero.
@MainActor
struct ChristmasTests {
    nonisolated private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Rome")!
        return calendar
    }()

    nonisolated private static func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    private let size = CGSize(width: 1000, height: 800)
    private let dockFrame = CGRect(x: 300, y: 0, width: 400, height: 60)
    private let window = WindowEdge(id: 1, rect: CGRect(x: 100, y: 300, width: 300, height: 200), visible: [100...400])

    /// Un diario dei regali tutto suo: i test non toccano quello vero.
    private func diary() -> GiftDiary {
        let name = "ChristmasTests-\(UUID().uuidString)"
        return GiftDiary(defaults: UserDefaults(suiteName: name)!, calendar: Self.calendar)
    }

    private func scene(on date: Date = date(2026, 12, 10), reduceMotion: Bool = false) -> SeasonScene {
        let scene = SeasonScene(size: size, screenOrigin: .zero, season: Snow())
        scene.reduceMotion = reduceMotion
        scene.christmas = ChristmasClock(now: { date }, calendar: Self.calendar, diary: diary())
        return scene
    }

    private func run(_ scene: SeasonScene, from start: TimeInterval = 0, seconds: TimeInterval) {
        for i in 0...Int(seconds * 60) { scene.step(at: start + TimeInterval(i) / 60) }
    }

    private func toys<T: Toy>(_ scene: SeasonScene, _ type: T.Type) -> [T] { scene.toys.compactMap { $0 as? T } }

    // MARK: - Date

    @Test(arguments: [
        (date(2026, 11, 30), false),
        (date(2026, 12, 1, 0, 0), true),
        (date(2026, 12, 25), true),
        (date(2027, 1, 6, 23, 59), true),
        (date(2027, 1, 7, 0, 0), false),
        (date(2026, 7, 15), false),
    ])
    func christmasTimeGoesFromTheFirstOfDecemberToEpiphany(_ date: Date, _ expected: Bool) {
        #expect(ChristmasDates.isChristmasTime(date, calendar: Self.calendar) == expected)
    }

    @Test func christmasEveIsTheTwentyFourth() {
        #expect(ChristmasDates.isEve(Self.date(2026, 12, 24, 0, 1), calendar: Self.calendar))
        #expect(!ChristmasDates.isEve(Self.date(2026, 12, 25, 0, 1), calendar: Self.calendar))
    }

    @Test func theCountdownSaysDaysHoursAndMinutesToMidnightOfTheTwentyFifth() throws {
        let fromToday = try #require(ChristmasDates.countdown(from: Self.date(2026, 11, 17, 10, 0), calendar: Self.calendar))
        #expect((fromToday.day, fromToday.hour, fromToday.minute) == (37, 14, 0))
        let fromEve = try #require(ChristmasDates.countdown(from: Self.date(2026, 12, 24, 18, 30), calendar: Self.calendar))
        #expect((fromEve.day, fromEve.hour, fromEve.minute) == (0, 5, 30))
    }

    @Test func onChristmasDayThereIsNoCountdownAndTheDayAfterItStartsAgain() throws {
        #expect(ChristmasDates.countdown(from: Self.date(2026, 12, 25, 9, 0), calendar: Self.calendar) == nil)
        let after = try #require(ChristmasDates.countdown(from: Self.date(2026, 12, 26, 0, 0), calendar: Self.calendar))
        #expect(after.day == 364)
    }

    // MARK: - Un regalo al giorno

    @Test func thereIsOneGiftADay() {
        let diary = diary()
        let today = Self.date(2026, 12, 10, 9)
        #expect(diary.canGive(on: today))
        diary.recordGift(on: today)
        #expect(!diary.canGive(on: Self.date(2026, 12, 10, 23)))
        #expect(diary.canGive(on: Self.date(2026, 12, 11, 0, 1)))
    }

    @Test func onTheEveTheGiftIsGuaranteedAndSantaComesMoreOften() {
        #expect(SantaVisits.carriesGift(eve: true, canGive: true, roll: 0.99))
        #expect(!SantaVisits.carriesGift(eve: false, canGive: true, roll: 0.99))
        #expect(SantaVisits.carriesGift(eve: false, canGive: true, roll: 0.1))
        #expect(!SantaVisits.carriesGift(eve: true, canGive: false, roll: 0))
        #expect(Tuning.santaEveInterval.upperBound < Tuning.santaInterval.lowerBound)
    }

    // MARK: - Babbo Natale

    @Test func santaDropsTheGiftOnTheDockOrAWindowAndOnlyOnceADay() throws {
        let scene = scene()
        scene.updateWindows([window], dock: dockFrame, ceiling: 780)
        let santa = try #require(scene.sendSanta())
        #expect(santa.carriesGift, "il primo passaggio chiesto dal menu porta il regalo di oggi")
        run(scene, seconds: 12)
        #expect(scene.santa == nil, "ha attraversato il cielo ed è uscito")
        let gift = try #require(toys(scene, Gift.self).first)
        #expect(gift.body.isResting)
        #expect(scene.ledges.contains { abs($0.y - gift.body.position.y) < 0.5 }, "sta su una finestra o sul Dock")
        let again = try #require(scene.sendSanta())
        #expect(!again.carriesGift, "oggi il regalo l'ha già lasciato")
    }

    @Test func twoSantasOnTwoScreensLeaveOnlyOneGift() {
        let diary = diary()
        let screens = [scene(), scene()]
        for scene in screens {
            scene.christmas.diary = diary
            scene.updateWindows([], dock: dockFrame, ceiling: 780)
            #expect(scene.sendSanta()?.carriesGift == true, "partono insieme: per entrambe oggi il regalo c'è ancora")
        }
        for scene in screens { run(scene, seconds: 12) }
        #expect(screens.map { toys($0, Gift.self).count }.reduce(0, +) == 1)
    }

    @Test func santaOnlyFliesInWinterAndOneAtATime() {
        let scene = scene()
        #expect(scene.sendSanta() != nil)
        #expect(scene.sendSanta() == nil)
        let summer = SeasonScene(size: size, screenOrigin: .zero, season: Summer())
        #expect(summer.sendSanta() == nil)
    }

    @Test func withReduceMotionSantaDoesNotFlyButTheGiftStillArrives() throws {
        let scene = scene(reduceMotion: true)
        scene.updateWindows([], dock: dockFrame, ceiling: 780)
        let santa = try #require(scene.sendSanta())
        #expect(santa.node.parent == nil, "niente slitta che attraversa lo schermo")
        run(scene, seconds: 3)
        let gift = try #require(toys(scene, Gift.self).first)
        #expect(gift.body.isResting)
    }

    // MARK: - Il regalo

    @Test func clickingTheGiftOpensItAndOutJumpsAGingerbreadMan() throws {
        let scene = scene()
        let gift = Gift(at: CGPoint(x: 500, y: 0))
        scene.add(gift)
        run(scene, seconds: 0.2)
        let feet = gift.body.position
        #expect(scene.grab(at: CGPoint(x: feet.x, y: feet.y + 8), time: 1))
        scene.letGo(at: CGPoint(x: feet.x, y: feet.y + 8), time: 1.05)
        #expect(gift.isOpen)
        #expect(toys(scene, GingerbreadMan.self).count == 1)
        gift.clicked()
        #expect(toys(scene, GingerbreadMan.self).count == 1, "un regalo si apre una volta sola")
    }

    // MARK: - Omino di pan di zenzero

    @Test func theGingerbreadManRunsAlongTheDockWithoutFallingOff() throws {
        let scene = scene()
        scene.updateWindows([], dock: dockFrame, ceiling: 780)
        let man = try #require(scene.sendGingerbreadMan())
        let dockTop = try #require(scene.dockLedge).y
        #expect(man.body.position.y == dockTop)
        var xs: [CGFloat] = []
        for i in 0...600 {
            scene.step(at: TimeInterval(i) / 60)
            if man.body.isResting { xs.append(man.body.position.x) }
        }
        #expect(man.body.position.y == dockTop, "è ancora sul Dock")
        #expect((xs.max() ?? 0) - (xs.min() ?? 0) > 200, "ha corso")
    }

    @Test func theGingerbreadManRunsAwayFromTheCursor() {
        let span: ClosedRange<CGFloat> = 0...1000
        let left = GingerbreadMan.run(x: 500, span: span, heading: 1, mouse: CGPoint(x: 540, y: 10), feetY: 0)
        #expect(left.heading == -1)
        #expect(left.fleeing)
        let calm = GingerbreadMan.run(x: 500, span: span, heading: 1, mouse: CGPoint(x: 900, y: 600), feetY: 0)
        #expect(calm.heading == 1)
        #expect(!calm.fleeing)
    }

    @Test func corneredTheGingerbreadManJumpsOverTheCursor() {
        let cornered = GingerbreadMan.run(x: 995, span: 0...1000, heading: 1, mouse: CGPoint(x: 960, y: 10), feetY: 0)
        #expect(cornered.heading == -1)
        #expect(cornered.jumps)
        let atTheEnd = GingerbreadMan.run(x: 995, span: 0...1000, heading: 1, mouse: CGPoint(x: 300, y: 300), feetY: 0)
        #expect(atTheEnd.heading == -1, "in fondo al bordo si gira")
        #expect(!atTheEnd.jumps)
    }

    @Test func catchingTheGingerbreadManTakesHimAway() throws {
        let scene = scene()
        let man = try #require(scene.sendGingerbreadMan())
        man.clicked()
        #expect(toys(scene, GingerbreadMan.self).isEmpty)
    }

    @Test func atMostThreeGingerbreadMen() {
        let scene = scene()
        for _ in 0..<5 { scene.sendGingerbreadMan() }
        #expect(toys(scene, GingerbreadMan.self).count == Tuning.maxGingerbreadMen)
    }

    // MARK: - Stagione e menu

    @Test func changingSeasonTakesAwaySantaGiftsAndGingerbreadMen() {
        let scene = scene()
        scene.sendSanta()
        scene.sendGingerbreadMan()
        scene.add(Gift(at: CGPoint(x: 500, y: 0)))
        scene.setSeason(Summer())
        #expect(scene.santa == nil)
        #expect(scene.toys.isEmpty)
    }

    @Test(arguments: [
        ("Fai passare Babbo Natale", "Call Santa Over"),
        ("Manda l'omino di pan di zenzero", "Send the Gingerbread Man"),
        ("Conto alla rovescia per Natale", "Christmas Countdown"),
        ("Buon Natale!", "Merry Christmas!"),
    ])
    func theChristmasStringsAreTranslated(_ italian: String, _ english: String) throws {
        let path = try #require(Bundle.main.path(forResource: "en", ofType: "lproj"))
        let bundle = try #require(Bundle(path: path))
        #expect(bundle.localizedString(forKey: italian, value: nil, table: nil) == english)
    }
}
