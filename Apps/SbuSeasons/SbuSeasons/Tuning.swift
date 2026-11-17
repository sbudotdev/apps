import CoreGraphics
import Foundation

/// I parametri fissi del motore, uguali per tutte le stagioni. Quelli regolabili dall'utente sono in `SnowSettings`,
/// quelli di una stagione nel suo file (es. `SnowTuning`).
nonisolated enum Tuning {
    // MARK: Lettura delle finestre

    /// Ogni quanto si legge dove sono le finestre.
    static let windowRefreshInterval: TimeInterval = 0.125

    // MARK: Animazione

    /// 60 fotogrammi al secondo, 30 a batteria per consumare meno (decisione di Matteo, MGS-416)
    /// e con "Riduci movimento" di macOS, che chiede meno movimento.
    static func framesPerSecond(onBattery: Bool, reduceMotion: Bool) -> Int { onBattery || reduceMotion ? 30 : 60 }

    // MARK: Riduci movimento

    /// Con "Riduci movimento" cade questa parte dei fiocchi, senza vento, oscillazione né rotazione.
    static let reducedMotionFlakes: CGFloat = 0.5

    // MARK: Particelle

    /// Schermo di riferimento per la quantità di fiocchi: altrove si scala sull'area.
    static let referenceScreenArea: CGFloat = 1440 * 900
    /// Quanto un fiocco può uscire di lato prima di rientrare dall'altro.
    static let sideMargin: CGFloat = 20

    // MARK: Cursore

    /// Quanto un movimento veloce del mouse trascina con sé i fiocchi (0…1).
    static let cursorDrag: CGFloat = 0.55
    /// Quanto velocemente la spinta del cursore si esaurisce (più alto = si fermano prima).
    static let cursorDamping: CGFloat = 1.8
    /// Raggio (in orizzontale) entro cui il cursore scava nella neve accumulata.
    static let scoopRadius: CGFloat = 14

    // MARK: Polvere

    /// Massimo numero di granelli di polvere in volo insieme.
    static let maxGrains = 1500
    /// Gravità dei granelli (pt/s²) e attrito dell'aria (più alto = cadono più piano).
    static let grainGravity: CGFloat = 520
    static let grainAirDrag: CGFloat = 1.2

    // MARK: Mucchi

    /// Larghezza di una colonna di neve, in punti.
    static let pileStep: CGFloat = 2
    /// Pendenza massima tra due colonne vicine: oltre, la neve "frana" di lato.
    static let pileMaxSlope: CGFloat = 0.8
    /// Sul Dock la neve arriva a questo multiplo dell'altezza massima.
    static let dockPileFactor: CGFloat = 1.75
    /// Raggio degli angoli del Dock.
    static let dockCornerRadius: CGFloat = 24
    /// Ogni quanto i mucchi franano e si ridisegnano (a ogni frame triplicava la CPU).
    static let pileSettleInterval: CGFloat = 0.1

    // MARK: Oggetti

    /// Gravità degli oggetti (pt/s²) e attrito quando poggiano su un bordo (più alto = si fermano prima).
    static let toyGravity: CGFloat = 1400
    static let toyFriction: CGFloat = 4
    /// Sotto questa velocità (pt/s) un oggetto che cade non rimbalza più: si ferma.
    static let toyMinBounce: CGFloat = 80
    /// Il lancio più veloce (pt/s): così un oggetto lanciato in alto sale al massimo di circa 800 pt
    /// e non sparisce oltre il bordo dello schermo.
    static let toyMaxThrow: CGFloat = 1500
    /// Entro questo tragitto (pt) tra pressione e rilascio è un clic, non un trascinamento.
    static let clickSlop: CGFloat = 4

    // MARK: Palle di neve e pupazzo

    /// Quanti granelli di neve posata (`Pile.scoop`) servono per una palla: circa 15 cm di finestra piena.
    static let snowballSnow = 120
    /// Le palle sciolte sullo schermo, al massimo: oltre sparisce la più vecchia.
    static let maxSnowballs = 12
    /// Una palla rotola: frena meno di un oggetto qualunque.
    static let snowballFriction: CGFloat = 0.8
    /// Tre palle tutte entro questa distanza (pt, tra i piedi) diventano un pupazzo.
    static let snowmanReach: CGFloat = 40

    // MARK: Neve che scivola via

    /// Una finestra che si sposta di più tra due letture (pt in 1/8 s, circa 320 pt/s) perde la neve;
    /// più piano, la neve resta sopra e la segue.
    static let slideOffDistance: CGFloat = 40

    // MARK: Palla di vetro

    /// La spinta verso l'alto della neve quando si scuote la palla di vetro (pt/s).
    static let globeLift: ClosedRange<CGFloat> = 250...650
    /// Dopo una scossa la palla di vetro riposa per qualche secondo: chi continua a scuotere non la rifà subito.
    static let globeRest: CGFloat = 3
}
