import AppKit
import SpriteKit

/// Il sereno: non cade niente. Per chi vuole solo gli oggetti, o lo sfondo, senza particelle.
/// Scegliendolo, ciò che si era posato si scioglie.
struct Clear: Season {
    static let id = "clear"
    var id: String { Self.id }
    var title: String { String(localized: "Sereno") }
    let symbol = "sun.min"
    var pileColor: NSColor { .white }
    var settles: Bool { false }
    var abundance: Double { 0 }

    func makeTexture() -> SKTexture { SKTexture() }
    func particle(depth: CGFloat) -> Particle {
        Particle(radius: 0, alpha: 0, fallSpeed: 0, swayAmplitude: 0, swayFrequency: 0)
    }
}
