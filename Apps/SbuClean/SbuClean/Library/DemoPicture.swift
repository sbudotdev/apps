import CoreImage
import UIKit

/// Pictures for the demo library: real photos from `DemoPhotos`, and landscapes and screens
/// drawn in code.
///
/// The same seed always draws the same picture, so duplicates are real duplicates for Vision.
nonisolated enum DemoPicture {
    /// A landscape of `size` points at scale 1.
    /// - Parameters:
    ///   - seed: Picks the colors and shapes.
    ///   - shift: Moves the sun and shapes sideways, as in a burst.
    ///   - size: The picture size in pixels.
    static func landscape(seed: Int, shift: CGFloat = 0, size: CGSize) -> UIImage {
        var generator = SeededGenerator(seed: UInt64(seed) &+ 1)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            let cg = context.cgContext
            let sky = color(&generator, from: 0.25, to: 0.85)
            sky.setFill()
            cg.fill(CGRect(origin: .zero, size: size))

            color(&generator, from: 0.75, to: 1).setFill()
            let radius = size.height * CGFloat.random(in: 0.07...0.14, using: &generator)
            let sunX = size.width * CGFloat.random(in: 0.15...0.85, using: &generator) + shift
            cg.fillEllipse(in: CGRect(x: sunX - radius, y: size.height * 0.2 - radius, width: radius * 2, height: radius * 2))

            for layer in 0..<3 {
                color(&generator, from: 0.05, to: 0.6).setFill()
                let base = size.height * (0.5 + 0.13 * CGFloat(layer))
                let path = UIBezierPath()
                path.move(to: CGPoint(x: 0, y: size.height))
                var x: CGFloat = 0
                while x <= size.width {
                    path.addLine(to: CGPoint(x: x, y: base + CGFloat.random(in: -0.08...0.08, using: &generator) * size.height))
                    x += size.width / 6
                }
                path.addLine(to: CGPoint(x: size.width, y: size.height))
                path.close()
                path.fill()
            }

            for _ in 0..<6 {
                color(&generator, from: 0, to: 1).setFill()
                let side = size.height * CGFloat.random(in: 0.05...0.2, using: &generator)
                let x = size.width * CGFloat.random(in: 0...1, using: &generator) + shift
                let y = size.height * CGFloat.random(in: 0.5...0.9, using: &generator)
                cg.fill(CGRect(x: x, y: y - side * 2, width: side, height: size.height))
            }
        }
    }

    /// A photo from `DemoPhotos`, filling `size`; `nil` when the build leaves it out.
    /// - Parameters:
    ///   - name: The file name without extension, such as `demo-64`.
    ///   - shift: Moves the picture sideways, as in a burst or a retake.
    ///   - blurred: Takes the focus out, as in a shaken shot.
    static func photo(named name: String, shift: CGFloat = 0, blurred: Bool = false, size: CGSize) -> UIImage? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "jpg"), var image = UIImage(contentsOfFile: url.path) else { return nil }

        if blurred, let cgImage = image.cgImage {
            let input = CIImage(cgImage: cgImage)
            let output = input.clampedToExtent().applyingGaussianBlur(sigma: 14).cropped(to: input.extent)
            if let blurredImage = CIContext().createCGImage(output, from: input.extent) {
                image = UIImage(cgImage: blurredImage)
            }
        }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            // A little larger than the frame, so a shifted picture still fills it.
            let zoom: CGFloat = shift == 0 ? 1 : 1.06
            let width = size.width * zoom
            let height = size.height * zoom
            image.draw(in: CGRect(x: (size.width - width) / 2 + shift, y: (size.height - height) / 2, width: width, height: height))
        }
    }

    /// A screen of a made-up app: bars and blocks on paper.
    static func screen(seed: Int, size: CGSize) -> UIImage {
        var generator = SeededGenerator(seed: UInt64(seed) &+ 7)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor(white: 0.96, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: size))
            var y = size.height * 0.08
            while y < size.height * 0.9 {
                let height = size.height * CGFloat.random(in: 0.04...0.12, using: &generator)
                color(&generator, from: 0.6, to: 0.95).setFill()
                UIBezierPath(roundedRect: CGRect(x: size.width * 0.05, y: y, width: size.width * 0.9, height: height), cornerRadius: 12).fill()
                y += height + size.height * 0.02
            }
        }
    }

    private static func color(_ generator: inout SeededGenerator, from low: CGFloat, to high: CGFloat) -> UIColor {
        UIColor(
            red: .random(in: low...high, using: &generator),
            green: .random(in: low...high, using: &generator),
            blue: .random(in: low...high, using: &generator),
            alpha: 1
        )
    }
}
