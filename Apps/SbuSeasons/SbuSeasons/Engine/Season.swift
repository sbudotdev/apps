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
    /// Quanto aggiunge al mucchio una particella che si posa (× "Velocità di accumulo"), estratto a caso
    /// a ogni posa: un intervallo largo e basso fa mucchi radi e irregolari.
    var pileGrowth: ClosedRange<CGFloat> { get }
    /// false = le particelle non si posano mai (lucciole, stelle cadenti); scegliendola, la neve posata si scioglie.
    var settles: Bool { get }
    /// Quante particelle rispetto a "Quantità" (1 = tante quante dice l'intensità, 0 = nessuna).
    var abundance: Double { get }
}

extension Season {
    var pileGrowth: ClosedRange<CGFloat> { 1...1 }
    var settles: Bool { true }
    var abundance: Double { 1 }
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
    /// Rotazione nel piano, in giri al secondo (0 = non gira).
    var spin: CGFloat = 0
    /// Ribaltamento, in giri al secondo: la particella si vede di taglio e poi dall'altra faccia (0 = mai).
    var flip: CGFloat = 0
    /// Il colore di questa particella sopra la texture (nil = la texture com'è).
    var tint: NSColor? = nil
    /// Velocità orizzontale propria in pt/s (una stella cadente va di traverso). Con `drift` la particella
    /// è orientata dove va, e quando esce di lato rinasce invece di rientrare dall'altra parte.
    var drift: CGFloat = 0
    /// Vagare in su e in giù, in punti, alla frequenza dell'oscillazione (le lucciole).
    var bob: CGFloat = 0
    /// Si accende e si spegne, in volte al secondo (0 = luce fissa).
    var pulse: CGFloat = 0
    /// Lunghezza rispetto alla larghezza: 1 = tonda, 8 = una scia lunga 8 volte quanto è alta.
    var length: CGFloat = 1
    /// Quanti punti sopra lo schermo rinasce in più: l'attesa prima di rivederla (una stella "ogni tanto").
    var gap: CGFloat = 0
}
