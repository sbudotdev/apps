import AppKit
import SpriteKit

/// L'inverno: fiocchi tondi color carta che cadono piano e si posano bianchi.
struct Snow: Season {
    static let id = "snow"
    var id: String { Self.id }
    var ambience: String? { "vento" }
    var title: String { String(localized: "Neve") }
    let symbol = "snowflake"
    /// Carta (valore chiaro) anche in aspetto scuro: è neve. Sulle finestre bianche si stacca
    /// perché è appena più calda del bianco.
    var pileColor: NSColor { Quaderno.paper.lightColor }

    func particle(depth: CGFloat) -> Particle {
        Particle(
            radius: 1.5 + depth * 3.5,
            alpha: SnowTuning.opacity.lowerBound + depth * (SnowTuning.opacity.upperBound - SnowTuning.opacity.lowerBound),
            fallSpeed: 22 + depth * 58,
            swayAmplitude: .random(in: 8...26),
            swayFrequency: .random(in: 0.3...0.9)
        )
    }

    /// Un pallino in `paper` (chiaro) che sfuma ai bordi in `ink-muted` (chiaro),
    /// così la neve resta visibile anche sopra le finestre bianche.
    func makeTexture() -> SKTexture {
        let diameter: CGFloat = 32
        let image = NSImage(size: NSSize(width: diameter, height: diameter), flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            let snow = Quaderno.paper.lightColor, rim = Quaderno.inkMuted.lightColor
            let colors = [
                snow.cgColor,
                snow.withAlphaComponent(SnowTuning.bodyOpacity).cgColor,
                rim.withAlphaComponent(SnowTuning.rimOpacity).cgColor,
                rim.withAlphaComponent(0).cgColor,
            ] as CFArray
            let locations: [CGFloat] = [0, 0.45, 0.75, 1]
            guard let gradient = CGGradient(
                colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                colors: colors,
                locations: locations
            ) else { return false }
            let center = CGPoint(x: rect.midX, y: rect.midY)
            ctx.drawRadialGradient(
                gradient,
                startCenter: center, startRadius: 0,
                endCenter: center, endRadius: rect.width / 2,
                options: []
            )
            return true
        }
        return SKTexture(image: image)
    }
}

/// I parametri fissi dei fiocchi. Quelli del motore sono in `Tuning`.
nonisolated enum SnowTuning {
    /// Opacità di un fiocco: i lontani più trasparenti, i vicini quasi pieni.
    static let opacity: ClosedRange<CGFloat> = 0.45...0.95
    /// Nella texture del fiocco: opacità della carta a metà raggio e del bordo in inchiostro tenue.
    static let bodyOpacity: CGFloat = 0.9
    static let rimOpacity: CGFloat = 0.45
}
