import AppKit
import SpriteKit

/// Le stelle cadenti: ogni tanto una scia chiara attraversa il cielo di traverso, veloce, e sparisce.
/// Non si posano.
struct Meteors: Season {
    static let id = "meteors"
    var id: String { Self.id }
    var title: String { String(localized: "Stelle cadenti") }
    let symbol = "moon.stars"
    var pileColor: NSColor { MeteorsTuning.head }
    var settles: Bool { false }
    var abundance: Double { MeteorsTuning.abundance }

    func particle(depth: CGFloat) -> Particle {
        let fall = CGFloat.random(in: MeteorsTuning.fallSpeed)
        return Particle(
            radius: 1.2 + depth * 1.2,
            alpha: MeteorsTuning.opacity.lowerBound + depth * (MeteorsTuning.opacity.upperBound - MeteorsTuning.opacity.lowerBound),
            fallSpeed: fall,
            swayAmplitude: 0,
            swayFrequency: 0,
            drift: fall * .random(in: MeteorsTuning.slant) * (Bool.random() ? 1 : -1),
            length: .random(in: MeteorsTuning.length),
            gap: .random(in: MeteorsTuning.gap)
        )
    }

    /// Una scia orizzontale: trasparente in coda (a sinistra), sempre più chiara fino alla testa tonda a destra.
    func makeTexture() -> SKTexture {
        let size = NSSize(width: 256, height: 16)
        let image = NSImage(size: size, flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            let tail = CGMutablePath()
            tail.move(to: CGPoint(x: 0, y: rect.midY))
            tail.addLine(to: CGPoint(x: rect.maxX - rect.height / 2, y: rect.minY + 2))
            tail.addLine(to: CGPoint(x: rect.maxX - rect.height / 2, y: rect.maxY - 2))
            tail.closeSubpath()
            ctx.saveGState()
            ctx.addPath(tail)
            ctx.clip()
            let colors = [MeteorsTuning.tail.withAlphaComponent(0).cgColor, MeteorsTuning.tail.cgColor] as CFArray
            guard let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: colors, locations: [0, 1])
            else { return false }
            ctx.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: rect.maxX, y: 0), options: [])
            ctx.restoreGState()
            ctx.setFillColor(MeteorsTuning.head.cgColor)
            ctx.fillEllipse(in: CGRect(x: rect.maxX - rect.height, y: 0, width: rect.height, height: rect.height))
            return true
        }
        return SKTexture(image: image)
    }
}

/// I colori e i numeri fissi delle stelle cadenti: contenuto, non interfaccia (li approva Matteo sullo screenshot).
nonisolated enum MeteorsTuning {
    /// Quante rispetto ai fiocchi di neve: con "Media", 2 o 3 per schermo, ognuna con la sua attesa.
    static let abundance = 0.01
    static let opacity: ClosedRange<CGFloat> = 0.7...1
    /// Velocità di discesa in pt/s; di lato vanno 1,5–2,2 volte tanto: una scia bassa sull'orizzonte.
    static let fallSpeed: ClosedRange<CGFloat> = 260...380
    static let slant: ClosedRange<CGFloat> = 1.5...2.2
    /// Lunghezza della scia rispetto al suo spessore.
    static let length: ClosedRange<CGFloat> = 28...44
    /// Quanti punti "sopra lo schermo" rinasce: a quella velocità, un'attesa di 8–45 s prima di ripassare.
    static let gap: ClosedRange<CGFloat> = 3_000...12_000
    /// La testa, quasi bianca, e la scia, azzurrina.
    static let head = NSColor(srgbRed: 1, green: 0.98, blue: 0.92, alpha: 1)
    static let tail = NSColor(srgbRed: 0.78, green: 0.86, blue: 1, alpha: 0.9)
}
