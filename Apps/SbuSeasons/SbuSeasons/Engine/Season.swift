import AppKit
import SpriteKit

/// Una stagione: che cosa cade (forma, colore, caduta) e di che colore è quando si posa.
/// Tutto il resto (finestre trasparenti, mucchi, cursore, frana) è del motore ed è uguale per tutte.
/// Come se ne aggiunge una: README, "Aggiungere una stagione".
protocol Season {
    /// Salvato nelle impostazioni: una volta uscita, non si cambia più.
    var id: String { get }
    /// Il nome nel menu, già tradotto.
    var title: String { get }
    /// Il simbolo SF nella barra dei menu.
    var symbol: String { get }
    /// Il colore di ciò che si posa sui bordi delle finestre e sul Dock.
    var pileColor: NSColor { get }
    /// La texture di una particella (fiocco, foglia…), creata una volta quando si sceglie la stagione.
    func makeTexture() -> SKTexture
    /// Una particella nuova. `depth`: 0 = lontana … 1 = vicina.
    func particle(depth: CGFloat) -> Particle
}

/// Com'è e come cade una particella, prima dei moltiplicatori delle Impostazioni.
nonisolated struct Particle {
    /// Raggio in punti (× "Dimensione").
    var radius: CGFloat
    var alpha: CGFloat
    /// Velocità di caduta in pt/s (× "Velocità di caduta").
    var fallSpeed: CGFloat
    /// Oscillazione laterale: ampiezza in punti, frequenza in oscillazioni al secondo.
    var swayAmplitude: CGFloat
    var swayFrequency: CGFloat
}
