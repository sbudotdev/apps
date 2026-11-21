import AppKit
import Testing
@testable import SbuSeasons

/// Il salvaschermo: lo sfondo scelto o uno diverso ogni volta, l'installazione in ~/Library/Screen Savers.
@MainActor
struct SaverTests {
    @Test func aChosenWallpaperIsAlwaysThatOne() {
        for _ in 0..<5 {
            #expect(SaverOptions.pick(chosen: "04-funivia", previous: "04-funivia").id == "04-funivia")
        }
    }

    @Test func eachTimeADifferentOne() {
        for _ in 0..<20 {
            let previous = Wallpaper.all.randomElement()?.id
            #expect(SaverOptions.pick(chosen: nil, previous: previous).id != previous)
        }
    }

    @Test func anOldChoiceThatNoLongerExistsPicksAtRandom() {
        let picked = SaverOptions.pick(chosen: "99-sparito", previous: nil)
        #expect(Wallpaper.all.contains { $0.id == picked.id })
    }

    @Test func optionsAreSaved() throws {
        let defaults = try #require(UserDefaults(suiteName: "saver-\(UUID().uuidString)"))
        var options = SaverOptions(defaults: defaults)
        #expect(options.wallpaperID == nil)
        #expect(options.showsEffect)
        options.wallpaperID = "08-sera-di-luglio"
        options.showsEffect = false
        options.save(to: defaults)
        let again = SaverOptions(defaults: defaults)
        #expect(again.wallpaperID == "08-sera-di-luglio")
        #expect(!again.showsEffect)
    }

    @Test func theSaverIsInsideTheApp() {
        #expect(SaverInstaller.bundled != nil, "manca Sbu Seasons.saver nelle risorse dell'app")
    }

    @Test func installingCopiesAndReplacesTheOldOne() throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "saver-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appending(path: "build/Sbu Seasons.saver")
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        try Data("nuovo".utf8).write(to: source.appending(path: "versione"))
        let folder = root.appending(path: "Screen Savers")
        let old = folder.appending(path: "Sbu Seasons.saver")
        try FileManager.default.createDirectory(at: old, withIntermediateDirectories: true)
        try Data("vecchio".utf8).write(to: old.appending(path: "versione"))

        let installed = try SaverInstaller.install(source, in: folder)
        #expect(installed == old)
        #expect(try String(contentsOf: installed.appending(path: "versione"), encoding: .utf8) == "nuovo")
    }

    /// La vista del salvaschermo si disegna: sfondo del momento ed effetto sopra, anche nell'anteprima piccola.
    @Test func theSaverDraws() throws {
        let defaults = try #require(UserDefaults(suiteName: "saver-\(UUID().uuidString)"))
        var options = SaverOptions(defaults: defaults)
        options.wallpaperID = "01-prima-neve"
        let view = SaverScene(frame: CGRect(x: 0, y: 0, width: 320, height: 200), options: options, moment: .sunset, bundle: .main)
        #expect(view.wallpaper.id == "01-prima-neve")
        #expect(view.backdrop != nil)
        #expect(view.scene?.season.id == Snow.id)
    }

    /// Da macOS 14 legacyScreenSaver spesso non chiama stopAnimation(): basta la notifica di fine per fermare tutto.
    @Test func theSaverStopsWhenMacOSClosesIt() throws {
        let defaults = try #require(UserDefaults(suiteName: "saver-\(UUID().uuidString)"))
        var options = SaverOptions(defaults: defaults)
        options.wallpaperID = "01-prima-neve"
        let center = NotificationCenter()
        let view = SaverScene(frame: CGRect(x: 0, y: 0, width: 320, height: 200), options: options, moment: .sunset,
                              bundle: .main, center: center)
        var stopped = false
        view.onStop = { stopped = true }
        #expect(view.scene != nil)
        center.post(name: SaverScene.willStop, object: nil)
        #expect(view.isStopped)
        #expect(view.scene == nil)
        #expect(stopped)
    }
}
