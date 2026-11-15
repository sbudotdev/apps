import AppKit
import SpriteKit

/// L'estate: semi di tarassaco, ombrellini bianchi che scendono piano, ondeggiano molto
/// e si posano color panna. Scelta da Matteo fra tre prototipi (MGS-431).
struct Summer: Season {
    static let id = "summer"
    var id: String { Self.id }
    var title: String { String(localized: "Estate") }
    let symbol = "sun.max"
    var pileColor: NSColor { SummerTuning.settled }

    func particle(depth: CGFloat) -> Particle {
        Particle(
            radius: 4 + depth * 7,
            alpha: SummerTuning.opacity.lowerBound + depth * (SummerTuning.opacity.upperBound - SummerTuning.opacity.lowerBound),
            fallSpeed: 10 + depth * 22,
            swayAmplitude: .random(in: SummerTuning.sway),
            swayFrequency: .random(in: 0.12...0.35)
        )
    }

    /// Un seme: il chicco marrone in basso, il gambo e un ventaglio di filamenti bianchi.
    func makeTexture() -> SKTexture {
        let side: CGFloat = 64
        let image = NSImage(size: NSSize(width: side, height: side), flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            let seed = CGPoint(x: rect.midX, y: rect.height * 0.18)
            let top = CGPoint(x: rect.midX, y: rect.height * 0.58)
            ctx.setLineCap(.round)
            ctx.setStrokeColor(SummerTuning.fluff.cgColor)
            ctx.setLineWidth(1.2)
            ctx.move(to: seed)
            ctx.addLine(to: top)
            ctx.strokePath()
            ctx.setLineWidth(0.9)
            let last = CGFloat(SummerTuning.filaments - 1)
            for i in 0..<SummerTuning.filaments {
                let angle = CGFloat.pi * (0.08 + 0.84 * CGFloat(i) / last)
                ctx.move(to: top)
                ctx.addLine(to: CGPoint(x: top.x + cos(angle) * 26, y: top.y + sin(angle) * 22))
            }
            ctx.strokePath()
            ctx.setFillColor(SummerTuning.seed.cgColor)
            ctx.fillEllipse(in: CGRect(x: seed.x - 2, y: seed.y - 4, width: 4, height: 8))
            return true
        }
        return SKTexture(image: image)
    }
}

/// I colori e i numeri fissi dei semi: contenuto, non interfaccia (li approva Matteo sulla registrazione).
nonisolated enum SummerTuning {
    /// Opacità di un seme: i lontani più trasparenti.
    static let opacity: ClosedRange<CGFloat> = 0.55...0.95
    /// Oscillazione laterale in punti: più ampia della neve (8…26), è un seme portato dal vento.
    static let sway: ClosedRange<CGFloat> = 20...50
    static let filaments = 13
    static let fluff = NSColor(white: 1, alpha: 0.75)
    static let seed = NSColor(srgbRed: 0.55, green: 0.45, blue: 0.30, alpha: 1)
    /// I semi posati sulle finestre e sul Dock.
    static let settled = NSColor(srgbRed: 0.96, green: 0.95, blue: 0.90, alpha: 1)
}
