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

    // MARK: Spazzaneve, slittino, funivia, albero

    /// La velocità dello spazzaneve (pt/s): un Dock di 800 pt in circa 5 s.
    static let ploughSpeed: CGFloat = 150
    /// Quanta neve prende lo spazzaneve per lato, dal centro (`Snowplough.blade`): da dietro le ruote alla lama.
    static let ploughBlade: CGFloat = 20
    /// Sotto questi granelli raccolti lo spazzaneve non lascia la montagnetta.
    static let moundMinSnow = 10
    /// Le montagnette sullo schermo, al massimo: oltre sparisce la più vecchia.
    static let maxMounds = 6
    /// Lo slittino frena pochissimo: scivola fino in fondo al bordo e scende sul prossimo.
    static let sledFriction: CGFloat = 0.15
    /// La spinta di un clic sullo slittino (pt/s).
    static let sledPush: CGFloat = 380
    static let maxSleds = 3
    /// La stazione della funivia: un palo sul fondo, a sinistra (pt dal bordo e altezza).
    static let cableStationX: CGFloat = 40
    static let cablePylonHeight: CGFloat = 60
    /// La velocità della cabina sul cavo (pt/s).
    static let cableSpeed: CGFloat = 70
    static let maxTrees = 5
    /// Le palline su un albero, al massimo.
    static let maxBaubles = 40

    // MARK: Natale

    /// Il primo passaggio di Babbo Natale dopo l'avvio (s), poi uno ogni 6–12 minuti; la vigilia ogni 2–4.
    static let santaFirstVisit: ClosedRange<CGFloat> = 20...60
    static let santaInterval: ClosedRange<CGFloat> = 360...720
    static let santaEveInterval: ClosedRange<CGFloat> = 120...240
    /// Mandato una volta dal menu, ripassa da solo ogni 1½–4 minuti, in qualunque giorno, finché cambi stagione
    /// o metti in pausa i giochi (SBU-114).
    static let santaLoopInterval: ClosedRange<CGFloat> = 90...240
    /// Un passaggio su due porta il regalo (finché oggi non l'ha lasciato).
    static let santaGiftChance = 0.5
    /// La velocità della slitta (pt/s): uno schermo da 1440 pt in circa 7 s.
    static let santaSpeed: CGFloat = 200
    /// L'altezza a cui vola, rispetto alla zona libera sotto la barra dei menu.
    static let santaAltitude: CGFloat = 0.9
    /// Quanto resta un regalo aperto prima di sparire (s).
    static let giftLinger: CGFloat = 3
    /// L'omino cammina a `gingerbreadWalk` e scappa a `gingerbreadDash` (pt/s) quando il cursore è più vicino
    /// di `gingerbreadFlee` pt. Si gira `gingerbreadTurn` pt prima della fine del bordo; il salto è `gingerbreadJump` pt/s.
    static let gingerbreadWalk: CGFloat = 90
    static let gingerbreadDash: CGFloat = 260
    static let gingerbreadFlee: CGFloat = 120
    static let gingerbreadTurn: CGFloat = 10
    static let gingerbreadJump: CGFloat = 520
    static let maxGingerbreadMen = 3

    // MARK: Personaggi e notte

    /// La volpe svegliata annusa per `foxSniff` s, poi cammina a `foxWalk` pt/s; dopo `foxAwake` s torna a dormire.
    static let foxSniff: CGFloat = 2.5
    static let foxAwake: CGFloat = 12
    static let foxWalk: CGFloat = 40
    /// La renna cammina a `reindeerWalk` pt/s; il naso si accende col cursore a meno di `reindeerNoseReach` pt.
    static let reindeerWalk: CGFloat = 26
    static let reindeerNoseReach: CGFloat = 90
    /// I semi in una mangiatoia piena; la cincia ne becca uno ogni `titPeck` s.
    static let feederSeeds = 6
    static let titPeck: CGFloat = 1.5
    /// Uno sbuffo di fumo dal camino della baita ogni `smokeInterval` s.
    static let smokeInterval: CGFloat = 0.7
    /// Quanto è forte l'alone di una fiamma (lanterna, candela).
    static let flameGlow: CGFloat = 0.75
    /// Di notte lo schermo si scurisce di tanto (0 = niente, 1 = nero); la notte finisce alle `nightEnds`.
    static let nightDim: CGFloat = 0.22
    static let nightEnds = 6

    // MARK: Neve che scivola via

    /// Una finestra che si sposta di più tra due letture (pt in 1/8 s, circa 320 pt/s) perde la neve;
    /// più piano, la neve resta sopra e la segue.
    static let slideOffDistance: CGFloat = 40

    // MARK: Palla di vetro

    /// La spinta verso l'alto della neve quando si scuote la palla di vetro (pt/s).
    static let globeLift: ClosedRange<CGFloat> = 250...650
    /// Dopo una scossa la palla di vetro riposa per qualche secondo: chi continua a scuotere non la rifà subito.
    static let globeRest: CGFloat = 3
    // MARK: Ora del giorno (sfondi)

    /// L'ora del Mac (decimale) a cui comincia ogni momento: la notte va dalle 21 all'alba delle 5.
    static let momentStarts: [DayMoment: Double] = [
        .dawn: 5, .sunrise: 6.5, .morning: 8, .noon: 11,
        .goldenHour: 16, .sunset: 18, .dusk: 19.5, .night: 21,
    ]
    /// Come cambia lo sfondo in ogni momento (`DayTint`). Mezzogiorno è il disegno com'è.
    static let momentLooks: [DayMoment: MomentLook] = [
        .dawn: MomentLook(exposure: -0.55, temperature: 7600, saturation: 0.7, contrast: 0.95,
                          veil: (0.95, 0.62, 0.66), veilOpacity: 0.28, veilReach: 0.75),
        .sunrise: MomentLook(exposure: -0.2, temperature: 5600, saturation: 0.9,
                             veil: (1, 0.78, 0.55), veilOpacity: 0.22, veilReach: 0.7),
        .morning: MomentLook(exposure: 0.05, temperature: 6900, saturation: 0.95),
        .noon: MomentLook(),
        .goldenHour: MomentLook(exposure: -0.05, temperature: 4700, saturation: 1.1,
                                veil: (1, 0.8, 0.4), veilOpacity: 0.16, veilReach: 0.8),
        .sunset: MomentLook(exposure: -0.35, temperature: 4200, saturation: 1.15, contrast: 1.05,
                            veil: (0.98, 0.45, 0.3), veilOpacity: 0.3, veilReach: 0.75),
        .dusk: MomentLook(exposure: -1.2, temperature: 8400, saturation: 0.8, contrast: 1.05,
                          veil: (0.4, 0.28, 0.6), veilOpacity: 0.4, veilReach: 0.9),
        .night: MomentLook(exposure: -2.4, temperature: 10000, saturation: 0.6, contrast: 1.1,
                           veil: (0.03, 0.06, 0.2), veilOpacity: 0.45, veilReach: 1),
    ]
    /// Uno sfondo con questa luminosità media (0…1) si scurisce quanto dice `momentLooks`; uno più scuro in proporzione,
    /// col quadrato del rapporto, ma almeno per `momentDarkFloor`.
    static let momentReferenceBrightness: CGFloat = 0.78
    static let momentDarkFloor: CGFloat = 0.2
    /// Ogni quanto (s) si guarda se è cominciato un altro momento.
    static let momentCheckInterval: TimeInterval = 60
    /// La qualità dei JPEG dei momenti, scritti una volta in Application Support.
    static let momentJPEGQuality = 0.9
}
