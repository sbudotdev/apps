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
    /// Banchi a tutto schermo che scorrono piano (nebbia, nuvole). Vuoto = nessuno.
    var banks: [Bank] { get }
    /// Lampi lontani che illuminano le nuvole. nil = mai.
    var lightning: Lightning? { get }
    /// Gocce sul vetro dello schermo. nil = niente.
    var glass: GlassRain? { get }
    /// Il sottofondo in loop (`vento`, `pioggia`), se i suoni sono accesi. nil = silenzio.
    var ambience: String? { get }
    /// Quanto sono grandi (diametro, pt) i pezzi che il cursore stacca da un mucchio: polvere per la neve,
    /// foglie e petali interi per autunno e primavera, che volano via invece di cadere come polvere.
    var pieceSize: ClosedRange<CGFloat> { get }
    /// Una particella che si posa resta lì, intera, per questi secondi e poi sfuma (i petali). nil = diventa mucchio.
    var linger: ClosedRange<CGFloat>? { get }
    /// Le particelle si radunano piano dove il cursore si ferma e si disperdono quando riparte (le lucciole).
    var gathers: Bool { get }
    /// Una particella che tocca il bordo scoperto di una finestra si rompe in scintille (le stelle cadenti).
    var shatters: Bool { get }
    /// La pioggia schizza sul bordo scoperto di una finestra (SBU-185): le gocce del temporale e quelle sul vetro.
    var splashes: Bool { get }
}

extension Season {
    var pileGrowth: ClosedRange<CGFloat> { 1...1 }
    var settles: Bool { true }
    var abundance: Double { 1 }
    var banks: [Bank] { [] }
    var lightning: Lightning? { nil }
    var glass: GlassRain? { nil }
    var ambience: String? { nil }
    var pieceSize: ClosedRange<CGFloat> { 2...4 }
    var linger: ClosedRange<CGFloat>? { nil }
    var gathers: Bool { false }
    var shatters: Bool { false }
    var splashes: Bool { false }
}

/// Un tipo di banco che attraversa lo schermo da sinistra a destra: strati di nebbia o nuvole.
/// Il disegno (bianco, poi tinto con `color`) è del motore (`Sky`).
nonisolated struct Bank {
    enum Shape { case mist, cloud }
    var shape: Shape
    /// Quanti su uno schermo largo 1440 pt, a intensità "Media" (scalati su larghezza e intensità).
    var count: Int
    /// Dove sta il centro, in frazioni dell'altezza dello schermo (0 = fondo, 1 = cima).
    var band: ClosedRange<CGFloat>
    /// Altezza in punti; la larghezza è `height × aspect`.
    var height: ClosedRange<CGFloat>
    var aspect: ClosedRange<CGFloat>
    /// Velocità verso destra, in pt/s.
    var speed: ClosedRange<CGFloat>
    var alpha: ClosedRange<CGFloat>
    var color: NSColor
}

/// Lampi lontani: ogni tanto le nuvole si illuminano due volte di fila, poi il tuono (se ci sono i suoni).
nonisolated struct Lightning {
    /// Secondi tra un lampo e l'altro.
    var every: ClosedRange<CGFloat>
    /// Quanto si illuminano le nuvole e il cielo (0…1).
    var strength: CGFloat
}

/// Pioggia sul vetro: gocce che si posano, si uniscono, scorrono giù e cadono dai bordi (`GlassDrops`).
nonisolated struct GlassRain {
    /// Gocce nuove al secondo su uno schermo di riferimento, a intensità "Media".
    var beads: CGFloat
    /// Raggio di una goccia appena posata, in punti.
    var size: ClosedRange<CGFloat>
    /// Da questo raggio una goccia è troppo pesante e scorre giù.
    var slide: CGFloat
    /// Massimo di gocce sul vetro su uno schermo di riferimento: oltre, la pioggia cade su quelle che ci sono.
    var most: Int
    var color: NSColor
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
