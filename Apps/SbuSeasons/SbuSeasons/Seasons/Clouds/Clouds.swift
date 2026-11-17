import AppKit
import SpriteKit

/// Le nuvole: banchi bianchi che attraversano piano la parte alta dello schermo.
struct Clouds: Season {
    static let id = "clouds"
    var id: String { Self.id }
    var title: String { String(localized: "Nuvole") }
    let symbol = "cloud"
    var pileColor: NSColor { CloudsTuning.color }
    var settles: Bool { false }
    var abundance: Double { 0 }
    var banks: [Bank] { CloudsTuning.banks }

    func makeTexture() -> SKTexture { SKTexture() }
    func particle(depth: CGFloat) -> Particle {
        Particle(radius: 0, alpha: 0, fallSpeed: 0, swayAmplitude: 0, swayFrequency: 0)
    }
}

/// I colori e i numeri fissi delle nuvole: contenuto, non interfaccia (li approva Matteo sullo screenshot).
nonisolated enum CloudsTuning {
    static let color = NSColor(srgbRed: 0.97, green: 0.97, blue: 0.99, alpha: 1)
    /// Le lontane più piccole, chiare e lente; le vicine più grandi.
    static let banks = [
        Bank(shape: .cloud, count: 3, band: 0.8...0.92, height: 70...110, aspect: 1.8...2.6, speed: 6...10,
             alpha: 0.3...0.4, color: color),
        Bank(shape: .cloud, count: 3, band: 0.86...0.98, height: 120...190, aspect: 2...2.8, speed: 12...20,
             alpha: 0.4...0.55, color: color),
    ]
}
