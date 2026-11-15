import AppKit
import SpriteKit

/// L'autunno: foglie rosse, arancio, ocra e marroni che scendono ondeggiando, girano su se stesse
/// e si ribaltano; si posano in mucchi radi e irregolari.
struct Autumn: Season {
    static let id = "autumn"
    var id: String { Self.id }
    var title: String { String(localized: "Autunno") }
    let symbol = "leaf"
    var pileColor: NSColor { AutumnTuning.settled }
    var pileGrowth: ClosedRange<CGFloat> { AutumnTuning.pileGrowth }

    func particle(depth: CGFloat) -> Particle {
        Particle(
            radius: 5 + depth * 7,
            alpha: AutumnTuning.opacity.lowerBound + depth * (AutumnTuning.opacity.upperBound - AutumnTuning.opacity.lowerBound),
            fallSpeed: 16 + depth * 34,
            swayAmplitude: .random(in: AutumnTuning.sway),
            swayFrequency: .random(in: 0.15...0.4),
            spin: .random(in: AutumnTuning.spin) * (Bool.random() ? 1 : -1),
            flip: .random(in: AutumnTuning.flip),
            tint: AutumnTuning.leaves.randomElement()
        )
    }

    /// Una foglia chiara con picciolo e nervature più scure: il colore lo dà la tinta di ogni foglia.
    func makeTexture() -> SKTexture {
        let side: CGFloat = 64
        let image = NSImage(size: NSSize(width: side, height: side), flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            let base = CGPoint(x: rect.midX, y: rect.height * 0.16)
            let tip = CGPoint(x: rect.midX + 2, y: rect.height * 0.96)
            let leaf = CGMutablePath()
            leaf.move(to: base)
            leaf.addCurve(to: tip, control1: CGPoint(x: rect.midX - 30, y: rect.height * 0.30),
                          control2: CGPoint(x: rect.midX - 14, y: rect.height * 0.86))
            leaf.addCurve(to: base, control1: CGPoint(x: rect.midX + 12, y: rect.height * 0.80),
                          control2: CGPoint(x: rect.midX + 28, y: rect.height * 0.34))
            ctx.addPath(leaf)
            ctx.setFillColor(NSColor.white.cgColor)
            ctx.fillPath()

            ctx.setLineCap(.round)
            ctx.setStrokeColor(AutumnTuning.vein.cgColor)
            ctx.setLineWidth(1.6)
            ctx.move(to: CGPoint(x: rect.midX - 1, y: 1))   // picciolo
            ctx.addLine(to: base)
            ctx.addLine(to: CGPoint(x: tip.x, y: tip.y - 6))   // nervatura centrale
            ctx.strokePath()
            ctx.setLineWidth(1)
            for i in 0..<4 {
                let y = rect.height * (0.30 + 0.14 * CGFloat(i))
                let reach = 13 - CGFloat(i) * 2.2
                ctx.move(to: CGPoint(x: rect.midX + CGFloat(i) * 0.5, y: y))
                ctx.addLine(to: CGPoint(x: rect.midX - reach, y: y + 7))
                ctx.move(to: CGPoint(x: rect.midX + CGFloat(i) * 0.5, y: y))
                ctx.addLine(to: CGPoint(x: rect.midX + reach, y: y + 7))
            }
            ctx.strokePath()
            return true
        }
        return SKTexture(image: image)
    }
}

/// I colori e i numeri fissi delle foglie: contenuto, non interfaccia (li approva Matteo sulla registrazione).
nonisolated enum AutumnTuning {
    /// Opacità di una foglia: le lontane un po' trasparenti, le vicine piene.
    static let opacity: ClosedRange<CGFloat> = 0.7...1
    /// Oscillazione laterale in punti: più ampia della neve (8…26), la foglia plana da una parte all'altra.
    static let sway: ClosedRange<CGFloat> = 30...70
    /// Giri al secondo nel piano (in un verso o nell'altro) e ribaltamenti al secondo.
    static let spin: ClosedRange<CGFloat> = 0.08...0.35
    static let flip: ClosedRange<CGFloat> = 0.15...0.5
    /// Le tinte delle foglie: rosso ruggine, arancio bruciato, ocra, marrone, rosso scuro.
    static let leaves: [NSColor] = [
        NSColor(srgbRed: 0.71, green: 0.28, blue: 0.17, alpha: 1),
        NSColor(srgbRed: 0.82, green: 0.46, blue: 0.18, alpha: 1),
        NSColor(srgbRed: 0.85, green: 0.64, blue: 0.25, alpha: 1),
        NSColor(srgbRed: 0.54, green: 0.35, blue: 0.20, alpha: 1),
        NSColor(srgbRed: 0.61, green: 0.18, blue: 0.14, alpha: 1),
    ]
    /// Le nervature, più scure del corpo della foglia prima della tinta.
    static let vein = NSColor(white: 0.62, alpha: 1)
    /// Le foglie posate sulle finestre e sul Dock.
    static let settled = NSColor(srgbRed: 0.62, green: 0.36, blue: 0.19, alpha: 1)
    /// Quanto aggiunge al mucchio una foglia posata: in media meno della neve, e molto variabile.
    static let pileGrowth: ClosedRange<CGFloat> = 0.1...1.1
}
