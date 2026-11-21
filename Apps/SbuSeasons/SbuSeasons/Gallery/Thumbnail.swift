import AppKit
import CoreImage
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

    /// L'anteprima nel momento del giorno (`DayTint`): piccola, si fa in un attimo.
    static func make(_ url: URL, moment: DayMoment, longSide: Int = 640, context: CIContext = CIContext()) -> CGImage? {
        guard let small = make(url, longSide: longSide) else { return nil }
        guard let look = Tuning.momentLooks[moment], !look.isIdentity else { return small }
        let input = CIImage(cgImage: small)
        let tinted = DayTint.apply(look, to: input, brightness: DayTint.brightness(of: input, context: context))
        return context.createCGImage(tinted, from: input.extent)
    }
}
