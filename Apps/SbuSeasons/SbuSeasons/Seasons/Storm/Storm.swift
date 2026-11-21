import AppKit
import SpriteKit

/// Il temporale: pioggia forte e obliqua sotto nuvole scure, gocce sul vetro, e ogni tanto un lampo lontano
/// che illumina le nuvole (poi il tuono, se i suoni sono accesi).
struct Storm: Season {
    static let id = "storm"
    var id: String { Self.id }
    var ambience: String? { "pioggia" }
    var title: String { String(localized: "Temporale") }
    let symbol = "cloud.bolt.rain"
    var pileColor: NSColor { RainTuning.water }
    var settles: Bool { false }
    var abundance: Double { StormTuning.abundance }
    var banks: [Bank] { [StormTuning.clouds] }
    var lightning: Lightning? { StormTuning.lightning }
    var glass: GlassRain? { StormTuning.glass }
    var splashes: Bool { true }

    func particle(depth: CGFloat) -> Particle {
        let fall = CGFloat.random(in: StormTuning.fallSpeed) * (0.7 + depth * 0.3)
        return Particle(
            radius: 0.5 + depth * 0.5,
            alpha: StormTuning.opacity.lowerBound + depth * (StormTuning.opacity.upperBound - StormTuning.opacity.lowerBound),
            fallSpeed: fall,
            swayAmplitude: 0,
            swayFrequency: 0,
            drift: fall * StormTuning.slant,
            length: .random(in: StormTuning.length)
        )
    }

    /// Una riga orizzontale (il motore la gira dove va): trasparente in coda, più chiara in testa.
    func makeTexture() -> SKTexture {
        let size = NSSize(width: 64, height: 4)
        let image = NSImage(size: size, flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            let colors = [RainTuning.water.withAlphaComponent(0).cgColor, RainTuning.water.cgColor] as CFArray
            guard let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: colors, locations: [0, 1])
            else { return false }
            ctx.addPath(CGPath(roundedRect: rect, cornerWidth: 2, cornerHeight: 2, transform: nil))
            ctx.clip()
            ctx.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: rect.maxX, y: 0), options: [])
            return true
        }
        return SKTexture(image: image)
    }
}

/// I colori e i numeri fissi del temporale: contenuto, non interfaccia (li approva Matteo sullo screenshot).
nonisolated enum StormTuning {
    /// Quante gocce rispetto ai fiocchi di neve.
    static let abundance = 0.6
    static let opacity: ClosedRange<CGFloat> = 0.25...0.55
    /// Cade veloce, in pt/s, un po' di traverso (verso sinistra).
    static let fallSpeed: ClosedRange<CGFloat> = 900...1300
    static let slant: CGFloat = -0.12
    /// Lunghezza della goccia rispetto al suo spessore.
    static let length: ClosedRange<CGFloat> = 12...20
    /// Nuvole basse e scure in cima allo schermo.
    static let clouds = Bank(shape: .cloud, count: 6, band: 0.86...1.02, height: 160...260, aspect: 2.2...3.2,
                             speed: 14...26, alpha: 0.5...0.7, color: NSColor(srgbRed: 0.36, green: 0.39, blue: 0.45, alpha: 1))
    /// Un lampo ogni 6–18 s.
    static let lightning = Lightning(every: 6...18, strength: 1)
    /// Più pioggia sul vetro, e gocce più grosse: scorrono prima. Meno gocce ferme della pioggia, che qui cade anche davanti.
    static let glass = GlassRain(beads: 45, size: 2...5.5, slide: 7, most: 220, color: RainTuning.water)
}
