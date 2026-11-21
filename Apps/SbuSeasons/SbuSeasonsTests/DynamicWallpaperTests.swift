import AppKit
import CoreImage
import ImageIO
import Testing
@testable import SbuSeasons

/// «Giorno e notte» fatto da macOS: un HEIC con gli otto momenti e l'ora di ognuno (`apple_desktop:h24`),
/// e lo sfondo che torna se macOS lo perde.
@MainActor
struct DynamicWallpaperTests {
    /// Un disegno piccolo in una cartella sua: il formato si prova senza i JPEG grandi del bundle.
    private func smallDrawing() throws -> (source: URL, folder: URL) {
        let folder = FileManager.default.temporaryDirectory.appending(path: "dynamic-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let source = folder.appending(path: "99-prova-16x10.jpg")
        let image = CIImage(color: CIColor(red: 0.6, green: 0.7, blue: 0.85)).cropped(to: CGRect(x: 0, y: 0, width: 64, height: 40))
        try CIContext().writeJPEGRepresentation(of: image, to: source, colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!)
        return (source, folder.appending(path: "Wallpapers"))
    }

    @Test func theTimelineHasEveryMomentAtItsHour() throws {
        let timeline = DynamicWallpaper.timeline
        #expect(timeline.items.count == DayMoment.allCases.count)
        for moment in DayMoment.allCases {
            let frame = try #require(DynamicWallpaper.frames.firstIndex(of: moment))
            let item = try #require(timeline.items.first { $0.frame == frame })
            #expect(item.time == Tuning.momentStarts[moment]! / 24)
        }
        // Mezzogiorno è il primo fotogramma: è quello che macOS mostra come anteprima, e quello del tema chiaro.
        #expect(DynamicWallpaper.frames.first == .noon)
        #expect(timeline.light == 0)
        #expect(timeline.dark == DynamicWallpaper.frames.firstIndex(of: .night))
    }

    @Test func theFileCarriesEightFramesAndTheClock() throws {
        let (source, folder) = try smallDrawing()
        defer { try? FileManager.default.removeItem(at: folder.deletingLastPathComponent()) }
        let file = try Wallpaper.prepareDynamic(source, in: folder)
        #expect(file.lastPathComponent == "99-prova-16x10-giorno-e-notte.heic")
        let images = try #require(CGImageSourceCreateWithURL(file as CFURL, nil))
        #expect(CGImageSourceGetCount(images) == DayMoment.allCases.count)
        #expect(DynamicWallpaper.timeline(of: file) == DynamicWallpaper.timeline)
        // Notte più scura di mezzogiorno: i fotogrammi sono davvero i momenti.
        let context = CIContext()
        func brightness(_ moment: DayMoment) throws -> CGFloat {
            let frame = try #require(CGImageSourceCreateImageAtIndex(images, DynamicWallpaper.frames.firstIndex(of: moment)!, nil))
            #expect(frame.width == 64 && frame.height == 40)
            return DayTint.brightness(of: CIImage(cgImage: frame), context: context)
        }
        #expect(try brightness(.night) < brightness(.noon) - 0.1)
    }

    @Test func theFileIsMadeOnceAndReused() throws {
        let (source, folder) = try smallDrawing()
        defer { try? FileManager.default.removeItem(at: folder.deletingLastPathComponent()) }
        let file = try Wallpaper.prepareDynamic(source, in: folder)
        let made = try FileManager.default.attributesOfItem(atPath: file.path)[.modificationDate] as? Date
        _ = try Wallpaper.prepareDynamic(source, in: folder)
        #expect(try FileManager.default.attributesOfItem(atPath: file.path)[.modificationDate] as? Date == made)
    }

    /// «Segue l'ora del Mac» è il file dinamico; un momento fisso è il suo JPEG.
    @Test func theChoicePicksTheFile() throws {
        let (source, folder) = try smallDrawing()
        defer { try? FileManager.default.removeItem(at: folder.deletingLastPathComponent()) }
        #expect(try Wallpaper.prepare(source, choice: .automatic, at: .now, in: folder).pathExtension == "heic")
        #expect(try Wallpaper.prepare(source, choice: .fixed(.dusk), at: .now, in: folder).lastPathComponent == "99-prova-16x10-dusk.jpg")
    }

    @Test func aFileWithoutTheClockIsNotDynamic() throws {
        let (source, folder) = try smallDrawing()
        defer { try? FileManager.default.removeItem(at: folder.deletingLastPathComponent()) }
        #expect(DynamicWallpaper.timeline(of: source) == nil)
    }

    // MARK: Ripristino

    @Test(arguments: [
        // (messo da noi, c'è adesso, va rimesso?)
        ("/tmp/walls/a.heic", "/System/Library/Desktop Pictures/Sonoma.heic", true),   // macOS l'ha perso: torna quello di sistema
        ("/tmp/walls/a.heic", nil, true),
        ("/tmp/walls/a.heic", "/System/Library/Wallpapers/.default/DefaultAerial.heic", true),   // l'aereo di default
        ("/tmp/walls/a.heic", "/tmp/walls/a.heic", false),   // è ancora lì
        ("/tmp/walls/a.heic", "/Users/me/Pictures/mare.heic", false),   // l'ha cambiato l'utente
        (nil, "/System/Library/Desktop Pictures/Sonoma.heic", false),   // non c'era uno dei nostri
    ] as [(String?, String?, Bool)])
    func aLostWallpaperComesBackOnlyWhereItWasOurs(_ placed: String?, _ current: String?, _ expected: Bool) {
        #expect(Wallpaper.wasLost(placed: placed.map { URL(filePath: $0) }, current: current.map { URL(filePath: $0) },
                                  folder: URL(filePath: "/tmp/walls")) == expected)
    }
}
