import AppKit
import CoreImage
import Testing
@testable import SbuSeasons

/// Sfondi per ora del giorno: il momento dall'ora del Mac, la scelta fissa, i file dei momenti, lo sfondo che segue l'effetto.
@MainActor
struct DayCycleTests {
    @Test(arguments: [
        (0, 0, DayMoment.night), (4, 59, .night), (5, 0, .dawn), (6, 29, .dawn), (6, 30, .sunrise),
        (8, 0, .morning), (12, 0, .noon), (16, 0, .goldenHour), (18, 15, .sunset), (19, 30, .dusk),
        (21, 0, .night), (23, 59, .night),
    ])
    func theMomentFollowsTheClock(_ hour: Int, _ minute: Int, _ expected: DayMoment) {
        #expect(DayMoment.at(hour: hour, minute: minute) == expected)
    }

    @Test func everyMomentHasAStartAndALook() {
        for moment in DayMoment.allCases {
            #expect(Tuning.momentStarts[moment] != nil)
            #expect(Tuning.momentLooks[moment] != nil)
        }
        #expect(Tuning.momentLooks[.noon]?.isIdentity == true)
        #expect(DayMoment.allCases.filter { Tuning.momentLooks[$0]?.isIdentity == true } == [.noon])
    }

    @Test func aFixedChoiceIgnoresTheClock() throws {
        let midnight = try #require(Calendar.current.date(bySettingHour: 0, minute: 30, second: 0, of: .now))
        #expect(MomentChoice.fixed(.goldenHour).moment(at: midnight) == .goldenHour)
        #expect(MomentChoice.automatic.moment(at: midnight) == .night)
    }

    @Test(arguments: [MomentChoice.automatic, .fixed(.dawn), .fixed(.night)])
    func theChoiceSurvivesSaving(_ choice: MomentChoice) {
        #expect(MomentChoice(rawValue: choice.rawValue) == choice)
    }

    @Test func anUnknownSavedChoiceIsAutomatic() {
        #expect(MomentChoice(rawValue: "eclipse") == .automatic)
    }

    /// Uno sfondo già scuro (la sera di luglio) si scurisce meno: di notte non deve diventare nero.
    @Test func darkWallpapersDarkenLess() {
        let bright = DayTint.darkening(-2, brightness: Tuning.momentReferenceBrightness)
        let dark = DayTint.darkening(-2, brightness: 0.35)
        #expect(bright == -2)
        #expect(dark > bright)
        #expect(dark <= -2 * Tuning.momentDarkFloor)
        #expect(DayTint.darkening(0.3, brightness: 0.1) == 0.3)   // schiarire non cambia
    }

    @Test(arguments: [DayMoment.night, .sunset, .dawn])
    func eachMomentChangesTheImage(_ moment: DayMoment) throws {
        let image = CIImage(color: CIColor(red: 0.6, green: 0.7, blue: 0.8)).cropped(to: CGRect(x: 0, y: 0, width: 4, height: 4))
        let context = CIContext()
        let look = try #require(Tuning.momentLooks[moment])
        let before = DayTint.brightness(of: image, context: context)
        let after = DayTint.brightness(of: DayTint.apply(look, to: image), context: context)
        #expect(abs(after - before) > 0.02)
        if moment == .night { #expect(after < before) }
    }

    @Test func noonIsTheDrawingAsItIs() throws {
        let image = CIImage(color: .gray).cropped(to: CGRect(x: 0, y: 0, width: 4, height: 4))
        #expect(DayTint.apply(MomentLook(), to: image) === image)
    }

    @Test func theMomentFileIsRenderedOnceAndReused() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "moments-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        let source = try #require(Wallpaper.all[0].url(for: CGSize(width: 1440, height: 900)))
        let night = try Wallpaper.prepare(source, moment: .night, in: folder)
        #expect(night.lastPathComponent == "01-prima-neve-16x10-night.jpg")
        #expect(FileManager.default.fileExists(atPath: night.path))
        let made = try FileManager.default.attributesOfItem(atPath: night.path)[.modificationDate] as? Date
        _ = try Wallpaper.prepare(source, moment: .night, in: folder)
        #expect(try FileManager.default.attributesOfItem(atPath: night.path)[.modificationDate] as? Date == made)
        // Mezzogiorno è la copia del disegno, con il nome di sempre.
        #expect(try Wallpaper.prepare(source, moment: .noon, in: folder).lastPathComponent == "01-prima-neve-16x10.jpg")
    }

    @Test func ourFilesAreRecognised() {
        let folder = URL(filePath: "/tmp/walls")
        #expect(Wallpaper.isOurs(URL(filePath: "/tmp/walls/01-prima-neve-16x10-night.jpg"), folder: folder))
        #expect(!Wallpaper.isOurs(URL(filePath: "/Users/me/Pictures/mare.heic"), folder: folder))
        #expect(!Wallpaper.isOurs(nil, folder: folder))
    }

    // MARK: Lo sfondo segue l'effetto

    @Test func theSuggestedWallpaperMatchesTheEffect() {
        #expect(Wallpaper.suggested(for: Rain.id, current: nil)?.id == "06-pioggia-di-marzo")
        #expect(Wallpaper.suggested(for: Autumn.id, current: Wallpaper.named("01-prima-neve"))?.id == "10-larici-di-ottobre")
    }

    /// Due sfondi hanno la neve: se c'è già uno dei due, resta quello (la galleria cambia sfondo e poi effetto).
    @Test func aWallpaperThatAlreadyFitsStays() {
        let eve = Wallpaper.named("05-vigilia-in-piazza")
        #expect(Wallpaper.suggested(for: Snow.id, current: eve)?.id == "05-vigilia-in-piazza")
    }

    @Test func anEffectWithoutAWallpaperChangesNothing() {
        #expect(Wallpaper.suggested(for: Summer.id, current: Wallpaper.all[0]) == nil)
        #expect(Wallpaper.suggested(for: Clear.id, current: nil) == nil)
    }

    @Test func theChosenWallpapersAreRememberedPerScreen() throws {
        let defaults = try #require(UserDefaults(suiteName: "day-\(UUID().uuidString)"))
        let prefs = WallpaperPrefs(defaults: defaults)
        #expect(prefs.choice == .automatic)
        #expect(!prefs.followsEffect)
        prefs.chosen["Studio Display"] = "07-ciliegi-in-fiore"
        prefs.choice = .fixed(.sunset)
        let again = WallpaperPrefs(defaults: defaults)
        #expect(again.chosen == ["Studio Display": "07-ciliegi-in-fiore"])
        #expect(again.choice == .fixed(.sunset))
    }

    // MARK: Inglese

    @Test(arguments: [
        ("Ora d'oro", "Golden Hour"), ("Segue l'ora del Mac", "Follows the Mac's Clock"), ("Tutti gli schermi", "All Screens"),
        ("Lo sfondo segue l'effetto", "Wallpaper Follows the Effect"), ("Novità della %@", "What's New in %@"),
        ("Uno diverso ogni volta", "A Different One Each Time"),
    ])
    func theNewStringsAreInEnglish(_ italian: String, _ english: String) throws {
        let path = try #require(Bundle.main.path(forResource: "en", ofType: "lproj"))
        #expect(Bundle(path: path)?.localizedString(forKey: italian, value: nil, table: nil) == english)
    }
}
