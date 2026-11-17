import AppKit
import Testing
@testable import SbuSeasons

/// La galleria degli sfondi: i file nel bundle, la versione larga, l'effetto consigliato, lo sfondo di prima.
@MainActor
struct GalleryTests {
    @Test func everyWallpaperHasBothFilesInTheBundle() throws {
        #expect(Wallpaper.all.count == 10)
        for wallpaper in Wallpaper.all {
            #expect(wallpaper.url(for: CGSize(width: 1440, height: 900)) != nil, "manca \(wallpaper.id)-16x10")
            #expect(wallpaper.url(for: CGSize(width: 3440, height: 1440)) != nil, "manca \(wallpaper.id)-21x9")
        }
    }

    @Test(arguments: [
        (CGSize(width: 1440, height: 900), "-16x10"),    // 16:10
        (CGSize(width: 1920, height: 1080), "-16x10"),   // 16:9
        (CGSize(width: 1280, height: 1024), "-16x10"),   // 5:4
        (CGSize(width: 3440, height: 1440), "-21x9"),    // ultrawide
        (CGSize(width: 5120, height: 1440), "-21x9"),    // 32:9
    ])
    func ultrawideScreensGetTheWideFile(_ screen: CGSize, _ suffix: String) {
        #expect(Wallpaper.all[0].fileName(for: screen).hasSuffix(suffix))
    }

    @Test func theRecommendedEffectIsARealSeason() {
        for wallpaper in Wallpaper.all {
            #expect(Seasons.named(wallpaper.effect).id == wallpaper.effect)
        }
        #expect(Wallpaper.all.first { $0.id == "06-pioggia-di-marzo" }?.effect == Rain.id)
        #expect(Wallpaper.all.first { $0.id == "02-baita-nel-bosco" }?.effect == Meteors.id)
    }

    private static func memory() throws -> WallpaperMemory {
        let defaults = try #require(UserDefaults(suiteName: "gallery-\(UUID().uuidString)"))
        return WallpaperMemory(defaults: defaults)
    }

    /// Chi usa la galleria e poi mette a mano una sua foto deve ritrovare quella, non la prima.
    @Test func itRemembersTheLatestOwnWallpaper() throws {
        let memory = try Self.memory()
        let latest = URL(filePath: "/Users/me/Pictures/montagna.heic")
        memory.remember(URL(filePath: "/Users/me/Pictures/mare.heic"), screen: "Studio Display")
        memory.remember(latest, screen: "Studio Display")
        #expect(memory.original(screen: "Studio Display") == latest)
        #expect(memory.original(screen: "LG UltraWide") == nil)
    }

    @Test func goingBackForgetsIt() throws {
        let memory = try Self.memory()
        memory.remember(URL(filePath: "/Users/me/Pictures/mare.heic"), screen: "Studio Display")
        memory.forget(screen: "Studio Display")
        #expect(memory.original(screen: "Studio Display") == nil)
    }

    @Test func theFileIsCopiedOutOfTheApp() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "walls-\(UUID().uuidString)")
        let source = try #require(Wallpaper.all[0].url(for: CGSize(width: 1440, height: 900)))
        let copy = try Wallpaper.install(source, in: folder)
        #expect(copy.deletingLastPathComponent().standardizedFileURL == folder.standardizedFileURL)
        #expect(FileManager.default.contentsEqual(atPath: copy.path, andPath: source.path))
        #expect(try Wallpaper.install(source, in: folder) == copy)   // la seconda volta non si rompe
    }

    /// Un JPEG aggiornato in una versione nuova dell'app deve sostituire la copia vecchia.
    @Test func anOutdatedCopyIsReplaced() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "walls-\(UUID().uuidString)")
        let source = try #require(Wallpaper.all[0].url(for: CGSize(width: 1440, height: 900)))
        let copy = try Wallpaper.install(source, in: folder)
        try Data("vecchio".utf8).write(to: copy)
        #expect(try Wallpaper.install(source, in: folder) == copy)
        #expect(FileManager.default.contentsEqual(atPath: copy.path, andPath: source.path))
    }
}

struct GalleryLocalizationTests {
    @Test(arguments: [("Sfondi…", "Wallpapers…"), ("Imposta sfondo", "Set Wallpaper"),
                      ("Lascia il mio schermo com'è", "Keep My Desktop as It Was"), ("Baita nel bosco", "Cabin in the Woods")])
    func theGalleryIsInEnglishToo(_ italian: String, _ english: String) throws {
        let bundle = try #require(Bundle.main.path(forResource: "en", ofType: "lproj").flatMap(Bundle.init(path:)))
        #expect(bundle.localizedString(forKey: italian, value: nil, table: nil) == english)
    }
}
