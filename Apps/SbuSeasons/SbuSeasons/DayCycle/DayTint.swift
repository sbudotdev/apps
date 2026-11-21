import CoreImage
import CoreImage.CIFilterBuiltins
import ImageIO
import UniformTypeIdentifiers

/// Fa di uno sfondo il suo momento del giorno con Core Image: luce, temperatura, colore e il velo di cielo.
/// Niente immagini nuove: si parte sempre dal file disegnato.
nonisolated enum DayTint {
    /// `brightness`: la luminosità media dello sfondo (0…1, `brightness(of:)`). Uno sfondo già scuro (la sera di luglio)
    /// si scurisce meno, se no di notte diventa nero.
    static func apply(_ look: MomentLook, to image: CIImage, brightness: CGFloat = Tuning.momentReferenceBrightness) -> CIImage {
        guard !look.isIdentity else { return image }
        let extent = image.extent
        let exposure = CIFilter.exposureAdjust()
        exposure.inputImage = image
        exposure.ev = Float(darkening(look.exposure, brightness: brightness))
        let warmth = CIFilter.temperatureAndTint()
        warmth.inputImage = exposure.outputImage
        warmth.neutral = CIVector(x: 6500, y: 0)
        warmth.targetNeutral = CIVector(x: look.temperature, y: 0)
        let colors = CIFilter.colorControls()
        colors.inputImage = warmth.outputImage
        colors.saturation = Float(look.saturation)
        colors.contrast = Float(look.contrast)
        guard var result = colors.outputImage else { return image }
        if look.veilOpacity > 0 {
            let gradient = CIFilter.linearGradient()
            gradient.point0 = CGPoint(x: extent.midX, y: extent.maxY)
            gradient.point1 = CGPoint(x: extent.midX, y: extent.maxY - extent.height * look.veilReach)
            gradient.color0 = CIColor(red: look.veil.red, green: look.veil.green, blue: look.veil.blue, alpha: look.veilOpacity)
            gradient.color1 = CIColor(red: look.veil.red, green: look.veil.green, blue: look.veil.blue, alpha: 0)
            if let veil = gradient.outputImage?.cropped(to: extent) {
                result = veil.composited(over: result)
            }
        }
        return result.cropped(to: extent)
    }

    /// Quanto si scurisce davvero: tutto su uno sfondo chiaro, meno su uno scuro (col quadrato del rapporto, fino a `momentDarkFloor`).
    static func darkening(_ exposure: CGFloat, brightness: CGFloat) -> CGFloat {
        guard exposure < 0 else { return exposure }
        let ratio = brightness / Tuning.momentReferenceBrightness
        return exposure * min(1, max(Tuning.momentDarkFloor, ratio * ratio))
    }

    /// La luminanza media dell'immagine (0…1), letta su un pixel solo da `CIAreaAverage`.
    static func brightness(of image: CIImage, context: CIContext) -> CGFloat {
        let average = CIFilter.areaAverage()
        average.inputImage = image
        average.extent = image.extent
        guard let output = average.outputImage else { return Tuning.momentReferenceBrightness }
        var pixel = [UInt8](repeating: 0, count: 4)
        context.render(output, toBitmap: &pixel, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                       format: .RGBA8, colorSpace: CGColorSpace(name: CGColorSpace.sRGB))
        return (0.2126 * CGFloat(pixel[0]) + 0.7152 * CGFloat(pixel[1]) + 0.0722 * CGFloat(pixel[2])) / 255
    }

    /// Legge `source`, applica il momento e scrive un JPEG in `destination`.
    static func render(_ source: URL, look: MomentLook, to destination: URL, context: CIContext = CIContext()) throws {
        guard let input = CIImage(contentsOf: source) else { throw CocoaError(.fileReadCorruptFile) }
        let space = CGColorSpace(name: CGColorSpace.sRGB)!
        let tinted = apply(look, to: input, brightness: brightness(of: input, context: context))
        try context.writeJPEGRepresentation(of: tinted, to: destination, colorSpace: space,
                                            options: [CIImageRepresentationOption(rawValue: kCGImageDestinationLossyCompressionQuality as String): Tuning.momentJPEGQuality])
    }
}
