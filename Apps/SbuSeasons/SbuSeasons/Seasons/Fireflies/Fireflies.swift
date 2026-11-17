import AppKit
import SpriteKit

/// Le lucciole: piccole luci gialloverdi che vagano piano per lo schermo, si accendono e si spengono.
/// Non cadono e non si posano: si vedono bene la sera, su uno sfondo scuro.
struct Fireflies: Season {
    static let id = "fireflies"
    var id: String { Self.id }
    var title: String { String(localized: "Lucciole") }
    let symbol = "sparkles"
    var pileColor: NSColor { FirefliesTuning.core }
    var settles: Bool { false }
    var abundance: Double { FirefliesTuning.abundance }

    func particle(depth: CGFloat) -> Particle {
        Particle(
            radius: 4 + depth * 5,
            alpha: FirefliesTuning.opacity.lowerBound + depth * (FirefliesTuning.opacity.upperBound - FirefliesTuning.opacity.lowerBound),
            fallSpeed: .random(in: FirefliesTuning.sink),
            swayAmplitude: .random(in: FirefliesTuning.wander),
            swayFrequency: .random(in: 0.06...0.16),
            bob: .random(in: FirefliesTuning.wander),
            pulse: .random(in: FirefliesTuning.pulse)
        )
    }

    /// Un punto di luce: il centro quasi bianco, poi gialloverde, e un alone che sfuma nel trasparente.
    func makeTexture() -> SKTexture {
        let side: CGFloat = 64
        let image = NSImage(size: NSSize(width: side, height: side), flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            let colors = [FirefliesTuning.spark.cgColor, FirefliesTuning.core.cgColor,
                          FirefliesTuning.core.withAlphaComponent(0.25).cgColor, NSColor.clear.cgColor] as CFArray
            guard let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: colors,
                                            locations: [0, 0.18, 0.45, 1]) else { return false }
            let center = CGPoint(x: rect.midX, y: rect.midY)
            ctx.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center,
                                   endRadius: side / 2, options: [])
            return true
        }
        return SKTexture(image: image)
    }
}

/// I colori e i numeri fissi delle lucciole: contenuto, non interfaccia (li approva Matteo sullo screenshot).
nonisolated enum FirefliesTuning {
    /// Quante rispetto ai fiocchi di neve (con "Media", circa 30 su uno schermo da 1440×900).
    static let abundance = 0.12
    /// Opacità quando sono accese: le lontane un po' più deboli.
    static let opacity: ClosedRange<CGFloat> = 0.65...1
    /// Scendono pianissimo, in pt/s: in qualche minuto attraversano lo schermo e rinascono in cima.
    static let sink: ClosedRange<CGFloat> = 1...4
    /// Quanto vagano di lato e in su e in giù, in punti.
    static let wander: ClosedRange<CGFloat> = 40...110
    /// Quante volte al secondo si accendono: una ogni 2–3 secondi, non tutte insieme.
    static let pulse: ClosedRange<CGFloat> = 0.3...0.55
    /// Il centro della luce e il colore della lucciola.
    static let spark = NSColor(srgbRed: 1, green: 0.99, blue: 0.86, alpha: 1)
    static let core = NSColor(srgbRed: 0.84, green: 0.93, blue: 0.36, alpha: 1)
}
