import AppKit
import Foundation
import os
import SpriteKit
import Testing
import UniformTypeIdentifiers
@testable import SbuSeasons

/// «Le tue immagini» (SBU-230): immagini importate che cadono al posto dei fiocchi. Copia, limite, file rifiutati,
/// moto salvato, ripristino che non le tocca.
@MainActor
struct MyImagesTests {
    /// Una cartella vuota a test: niente della cartella vera dell'app.
    private let library = ImageLibrary(folder: FileManager.default.temporaryDirectory.appending(path: "sbu-230-\(UUID().uuidString)"))

    /// Un'immagine di prova di `width`×`height` pixel, nel formato chiesto, fuori dalla cartella della libreria.
    private func picture(_ type: UTType, width: Int = 40, height: Int = 20) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: "sbu-230-\(UUID().uuidString).\(type.preferredFilenameExtension ?? "img")")
        if type == .svg {
            try Data(#"<svg xmlns="http://www.w3.org/2000/svg" width="\#(width)" height="\#(height)"><rect width="\#(width)" height="\#(height)" fill="red"/></svg>"#.utf8).write(to: url)
            return url
        }
        let context = try #require(CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                                             space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                             bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.setFillColor(NSColor.red.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let image = try #require(context.makeImage())
        let destination = try #require(CGImageDestinationCreateWithURL(url as CFURL, type.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, nil)
        #expect(CGImageDestinationFinalize(destination))
        return url
    }

    @Test(arguments: [UTType.png, .jpeg, .heic, .svg])
    func importCopiesTheFileIntoTheFolder(_ type: UTType) async throws {
        let source = try picture(type)
        try await library.importFile(at: source)
        let name = try #require(library.names.first)
        let copy = library.url(for: name)
        #expect(copy.deletingLastPathComponent().standardizedFileURL == library.folder.standardizedFileURL)
        #expect(try Data(contentsOf: copy) == Data(contentsOf: source))
        #expect(FileManager.default.fileExists(atPath: source.path()))   // l'originale resta dov'era
        // Una libreria nuova sulla stessa cartella la ritrova: al riavvio ci sono ancora.
        #expect(ImageLibrary(folder: library.folder).names == [name])
    }

    @Test func atMostTenImages() async throws {
        for _ in 0..<Tuning.imagesMax { try await library.importFile(at: picture(.png)) }
        await #expect(throws: ImageImportError.full) { try await library.importFile(at: try picture(.png)) }
        #expect(library.names.count == Tuning.imagesMax)
    }

    @Test func brokenFileIsRefused() async throws {
        let broken = FileManager.default.temporaryDirectory.appending(path: "sbu-230-\(UUID().uuidString).png")
        try Data("non sono un'immagine".utf8).write(to: broken)
        await #expect(throws: ImageImportError.unreadable) { try await library.importFile(at: broken) }
        #expect(library.names.isEmpty)
    }

    @Test func tooLargeFileIsRefused() async throws {
        let big = FileManager.default.temporaryDirectory.appending(path: "sbu-230-\(UUID().uuidString).png")
        #expect(FileManager.default.createFile(atPath: big.path(), contents: nil))
        let handle = try FileHandle(forWritingTo: big)
        try handle.truncate(atOffset: UInt64(Tuning.imageMaxBytes + 1))   // un file rado: niente 20 MB veri su disco
        try handle.close()
        await #expect(throws: ImageImportError.tooLarge) { try await library.importFile(at: big) }
        #expect(library.names.isEmpty)
    }

    @Test func errorsSayWhatHappened() {
        for error in [ImageImportError.full, .tooLarge, .unreadable] {
            #expect(!(error.errorDescription ?? "").isEmpty)
        }
    }

    @Test func removeTakesAwayOnlyThatImage() async throws {
        try await library.importFile(at: picture(.png))
        try await library.importFile(at: picture(.jpeg))
        let first = library.names[0]
        library.remove(first)
        #expect(library.names.count == 1 && !library.names.contains(first))
        #expect(!FileManager.default.fileExists(atPath: library.url(for: first).path()))
    }

    @Test func importOrderIsKept() async throws {
        try await library.importFile(at: picture(.png))
        try await library.importFile(at: picture(.svg))
        #expect(library.names.last?.hasSuffix(".svg") == true)
    }

    /// Una foto grande diventa una texture piccola: lato massimo `imageSide` pt (il doppio in pixel, per il Retina).
    @Test func textureIsSmallAndKeepsItsShape() async throws {
        try await library.importFile(at: picture(.png, width: 1200, height: 600))
        let image = try #require(library.smallImage(library.names[0]))
        #expect(image.width == Int(Tuning.imageSide * 2))
        #expect(image.height == Int(Tuning.imageSide))
    }

    @Test func untickedImagesDoNotFall() async throws {
        try await library.importFile(at: picture(.png))
        try await library.importFile(at: picture(.jpeg))
        #expect(library.textures(skipping: []).count == 2)
        #expect(library.textures(skipping: [library.names[0]]).count == 1)
        #expect(library.textures(skipping: library.names).isEmpty)
    }

    @Test func motionIsSavedAndReadBack() throws {
        var values = SnowSettings()
        #expect(values.imagesMotion == .snow)
        values.imagesMotion = .rain
        values.imagesOff = ["a.png"]
        #expect(SnowSettings(saved: try JSONEncoder().encode(values)) == values)
        // Una scelta che questa versione non conosce torna come la neve.
        #expect(SnowSettings(saved: Data(#"{"imagesMotion": "bubbles"}"#.utf8)).imagesMotion == .snow)
    }

    /// «Ripristina» rimette i valori predefiniti, ma le immagini importate restano nella loro cartella.
    @Test func resetKeepsTheImportedImages() async throws {
        try await library.importFile(at: picture(.png))
        let before = Settings.shared.values
        defer { Settings.shared.values = before }
        Settings.shared.reset()
        #expect(library.names.count == 1)
        #expect(ImageLibrary(folder: library.folder).names.count == 1)
    }

    @Test func withoutImagesTheEffectInvitesToImport() async throws {
        let season = MyImages(library: library)
        #expect(season.abundance == 0)
        #expect(season.invitation != nil)
        try await library.importFile(at: picture(.png))
        #expect(season.abundance > 0)
        #expect(season.invitation == nil)
        #expect(season.particle(depth: 0.5).texture != nil)
    }

    /// Immagini importate ma tutte senza spunta: l'invito dice di spuntarne una, non di importarle (QA SBU-231).
    @Test func allUntickedTheEffectInvitesToTickOne() async throws {
        try await library.importFile(at: picture(.png))
        let before = Settings.shared.values
        defer { Settings.shared.values = before }
        Settings.shared.values.imagesOff = library.names
        let season = MyImages(library: library)
        #expect(season.abundance == 0)
        #expect(season.invitation == String(localized: "Spunta almeno un'immagine in Impostazioni → Le tue immagini."))
    }

    /// Importazione e miniature leggono il file fuori dal thread principale (QA SBU-231): le Impostazioni non si bloccano.
    @Test func importAndThumbnailsReadOffTheMainThread() async throws {
        let onMain = OSAllocatedUnfairLock(initialState: [Bool]())
        let read: @Sendable (URL) -> Data? = { url in
            onMain.withLock { $0.append(Thread.isMainThread) }
            return try? Data(contentsOf: url)
        }
        let library = ImageLibrary(folder: library.folder, read: read)
        try await library.importFile(at: picture(.png))
        let name = try #require(library.names.first)
        // Una libreria nuova (come al riavvio) non ha la miniatura in memoria: la rilegge dal disco.
        #expect(await ImageLibrary(folder: library.folder, read: read).loadSmallImage(name) != nil)
        #expect(onMain.withLock { $0 } == [false, false])
    }

    /// Ogni cambio di immagini o di scelta cambia la revisione: la scena rifà le particelle.
    @Test func revisionFollowsTheImages() async throws {
        let season = MyImages(library: library)
        let empty = season.revision
        try await library.importFile(at: picture(.png))
        #expect(season.revision != empty)
    }

    @Test func eachMotionFallsItsWay() {
        let snow = MyImages.particle(depth: 1, motion: .snow, texture: nil)
        let leaves = MyImages.particle(depth: 1, motion: .leaves, texture: nil)
        let rain = MyImages.particle(depth: 1, motion: .rain, texture: nil)
        #expect(snow.spin == 0 && snow.swayAmplitude > 0)
        #expect(leaves.spin != 0 && leaves.flip > 0 && leaves.swayAmplitude > snow.swayAmplitude)
        #expect(rain.swayAmplitude == 0 && rain.spin == 0 && rain.drift == 0)
        #expect(rain.fallSpeed > snow.fallSpeed * 4)
    }

    /// Nella scena: senza immagini l'invito e niente particelle; importata una, cadono quelle, nelle sue proporzioni.
    @Test func sceneShowsTheInvitationThenTheImages() async throws {
        let scene = SeasonScene(size: CGSize(width: 800, height: 600), screenOrigin: .zero, season: Snow())
        scene.setSeason(MyImages(library: library))
        #expect(scene.flakeCount == 0)
        #expect(scene.invitation.text != nil)
        try await library.importFile(at: picture(.png, width: 400, height: 200))
        scene.step(at: 0)
        scene.step(at: 1.0 / 60)
        #expect(scene.flakeCount > 0)
        #expect(scene.invitation.text == nil)
        let sprite = try #require(scene.children.compactMap { $0 as? SKSpriteNode }.first { $0.texture?.size().width == Tuning.imageSide * 2 })
        #expect(abs(sprite.size.width - sprite.size.height * 2) < 0.01)
    }

    @Test func listedAsAnEffect() {
        #expect(Seasons.named(MyImages.id) is MyImages)
    }
}
