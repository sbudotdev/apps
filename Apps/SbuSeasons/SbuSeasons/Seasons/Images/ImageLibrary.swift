import AppKit
import SpriteKit

/// Le immagini importate (SBU-230): copie dei file in Application Support, mai fuori dal Mac.
/// La cartella è l'elenco: niente da salvare a parte, e «Ripristina» non la tocca.
@Observable
final class ImageLibrary {
    /// Nei test una cartella temporanea: i test non vedono né cambiano le immagini di chi usa l'app.
    static let shared = ImageLibrary(folder: ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil
        ? URL.applicationSupportDirectory.appending(path: "Sbu Seasons/Images")
        : FileManager.default.temporaryDirectory.appending(path: "sbu-seasons-tests-images-\(UUID().uuidString)"))

    let folder: URL
    /// I nomi dei file, nell'ordine in cui sono stati importati (il nome comincia con l'ora dell'importazione).
    private(set) var names: [String] = []
    /// Cambia a ogni importazione o rimozione: la scena rifà le particelle.
    private(set) var revision = 0
    @ObservationIgnored private var small: [String: CGImage] = [:]
    @ObservationIgnored private var textureCache: [String: SKTexture] = [:]

    init(folder: URL) {
        self.folder = folder
        names = ((try? FileManager.default.contentsOfDirectory(atPath: folder.path())) ?? [])
            .filter { !$0.hasPrefix(".") }
            .sorted()
    }

    func url(for name: String) -> URL { folder.appending(path: name) }

    /// Controlla il file e ne mette una copia nella cartella. Un file troppo grande o rovinato non entra.
    func importFile(at source: URL) throws(ImageImportError) {
        guard names.count < Tuning.imagesMax else { throw .full }
        let bytes = (try? source.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        guard bytes <= Tuning.imageMaxBytes else { throw .tooLarge }
        guard let data = try? Data(contentsOf: source), let shrunk = Self.shrink(data) else { throw .unreadable }
        let ext = source.pathExtension.lowercased()
        let name = String(format: "%013.0f-", Date.now.timeIntervalSince1970 * 1000) + UUID().uuidString + (ext.isEmpty ? "" : ".\(ext)")
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try data.write(to: url(for: name))
        } catch {
            throw .unreadable
        }
        small[name] = shrunk
        names.append(name)
        revision += 1
    }

    func remove(_ name: String) {
        try? FileManager.default.removeItem(at: url(for: name))
        names.removeAll { $0 == name }
        small[name] = nil
        textureCache[name] = nil
        revision += 1
    }

    /// L'immagine ridotta (lato lungo `imageSide` pt, al doppio in pixel), fatta una volta per file.
    func smallImage(_ name: String) -> CGImage? {
        if let cached = small[name] { return cached }
        guard let data = try? Data(contentsOf: url(for: name)), let shrunk = Self.shrink(data) else { return nil }
        small[name] = shrunk
        return shrunk
    }

    /// Le texture che cadono, tranne quelle tolte con la casella. Un file sparito o rovinato si salta.
    func textures(skipping off: [String]) -> [SKTexture] {
        names.filter { !off.contains($0) }.compactMap { name in
            if let cached = textureCache[name] { return cached }
            guard let image = smallImage(name) else { return nil }
            let texture = SKTexture(cgImage: image)
            textureCache[name] = texture
            return texture
        }
    }

    /// L'immagine con il lato lungo di `imageSide` × 2 pixel, in proporzione; nil se il file non è un'immagine.
    /// PNG, JPEG e HEIC con la miniatura di ImageIO (una foto enorme non si decodifica intera); SVG con `NSImage`.
    static func shrink(_ data: Data) -> CGImage? {
        let side = Int(Tuning.imageSide * 2)
        if let source = CGImageSourceCreateWithData(data as CFData, nil), CGImageSourceGetCount(source) > 0 {
            let options = [kCGImageSourceCreateThumbnailFromImageAlways: true, kCGImageSourceCreateThumbnailWithTransform: true,
                           kCGImageSourceThumbnailMaxPixelSize: side] as CFDictionary
            return CGImageSourceCreateThumbnailAtIndex(source, 0, options)
        }
        guard let image = NSImage(data: data) else { return nil }
        let size = image.size
        guard size.width > 0, size.height > 0, size.width.isFinite, size.height.isFinite else { return nil }
        let scale = CGFloat(side) / max(size.width, size.height)
        let target = CGRect(x: 0, y: 0, width: max((size.width * scale).rounded(), 1), height: max((size.height * scale).rounded(), 1))
        guard let context = CGContext(data: nil, width: Int(target.width), height: Int(target.height), bitsPerComponent: 8, bytesPerRow: 0,
                                      space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return nil }
        let graphics = NSGraphicsContext(cgContext: context, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = graphics
        image.draw(in: target)
        NSGraphicsContext.restoreGraphicsState()
        return context.makeImage()
    }
}
