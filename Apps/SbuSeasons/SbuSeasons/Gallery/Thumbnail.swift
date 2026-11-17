import AppKit
import ImageIO

/// Un'anteprima piccola di un file grande: ImageIO legge il JPEG già ridotto, senza aprire 5000 pixel.
nonisolated enum Thumbnail {
    static func make(_ url: URL, longSide: Int = 640) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: longSide,
            kCGImageSourceCreateThumbnailWithTransform: true,
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }
}
