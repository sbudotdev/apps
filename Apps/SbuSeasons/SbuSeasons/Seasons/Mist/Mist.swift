import AppKit
import SpriteKit

/// La nebbia: strati bassi e sfumati che scorrono lenti in fondo allo schermo, a velocità diverse.
struct Mist: Season {
    static let id = "mist"
    var id: String { Self.id }
    var title: String { String(localized: "Nebbia") }
    let symbol = "cloud.fog"
    var pileColor: NSColor { MistTuning.color }
    var settles: Bool { false }
    var abundance: Double { 0 }
    var banks: [Bank] { MistTuning.layers }

    func makeTexture() -> SKTexture { SKTexture() }
    func particle(depth: CGFloat) -> Particle {
        Particle(radius: 0, alpha: 0, fallSpeed: 0, swayAmplitude: 0, swayFrequency: 0)
    }
}

/// I colori e i numeri fissi della nebbia: contenuto, non interfaccia (li approva Matteo sullo screenshot).
nonisolated enum MistTuning {
    static let color = NSColor(srgbRed: 0.9, green: 0.92, blue: 0.94, alpha: 1)
    /// Tre strati: il più basso più denso e lento, quelli sopra più leggeri. Trasparenti: sotto si lavora.
    static let layers = [
        Bank(shape: .mist, count: 3, band: 0.02...0.12, height: 160...240, aspect: 3.5...5, speed: 5...9,
             alpha: 0.28...0.38, color: color),
        Bank(shape: .mist, count: 3, band: 0.12...0.24, height: 120...200, aspect: 3.5...5, speed: 9...14,
             alpha: 0.18...0.26, color: color),
        Bank(shape: .mist, count: 2, band: 0.24...0.36, height: 100...160, aspect: 4...6, speed: 13...20,
             alpha: 0.1...0.16, color: color),
    ]
}
