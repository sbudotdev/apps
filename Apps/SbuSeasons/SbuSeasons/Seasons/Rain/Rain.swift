import AppKit
import SpriteKit

/// La pioggia sul vetro: gocce che si posano sullo schermo, si uniscono, scorrono giù e cadono dai bordi
/// delle finestre e del Dock. Non cade niente davanti: è come guardare fuori da una finestra bagnata.
struct Rain: Season {
    static let id = "rain"
    var id: String { Self.id }
    var ambience: String? { "pioggia" }
    var title: String { String(localized: "Pioggia sul vetro") }
    let symbol = "cloud.drizzle"
    var pileColor: NSColor { RainTuning.water }
    var settles: Bool { false }
    var abundance: Double { 0 }
    var glass: GlassRain? { RainTuning.glass }
    var lightning: Lightning? { RainTuning.lightning }
    var splashes: Bool { true }

    func makeTexture() -> SKTexture { SKTexture() }
    func particle(depth: CGFloat) -> Particle {
        Particle(radius: 0, alpha: 0, fallSpeed: 0, swayAmplitude: 0, swayFrequency: 0)
    }
}

/// I colori e i numeri fissi della pioggia: contenuto, non interfaccia (li approva Matteo sullo screenshot).
nonisolated enum RainTuning {
    /// L'acqua: un azzurro grigio, quasi trasparente nella goccia.
    static let water = NSColor(srgbRed: 0.72, green: 0.8, blue: 0.88, alpha: 1)
    /// Con "Media" 30 gocce al secondo su uno schermo da 1440×900, al massimo 400 sul vetro.
    static let glass = GlassRain(beads: 30, size: 2...5, slide: 7, most: 400, color: water)
    /// Ogni tanto un lampo lontano anche nella pioggia: più di rado e più debole del temporale (SBU-177).
    static let lightning = Lightning(every: 40...120, strength: 0.7)
    /// Il vetro asciugato dal cursore torna coperto in 3–6 s, a caso per ogni tratto (SBU-228).
    static let wipeClose: ClosedRange<CGFloat> = 3...6
    /// Una goccia asciugata svanisce in 0,15 s (con Riduci movimento sparisce subito).
    static let wipeFade: TimeInterval = 0.15
}
