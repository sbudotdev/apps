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
    /// `highRate`: «120 fps sugli schermi ProMotion» (spento di base, SBU-177), solo se lo schermo li fa (`maxFPS`).
    static func framesPerSecond(onBattery: Bool, reduceMotion: Bool, highRate: Bool = false, maxFPS: Int = 60) -> Int {
        if onBattery || reduceMotion { return 30 }
        return highRate && maxFPS >= 120 ? 120 : 60
    }

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
    /// Fino a 3 alberi, come in KoiArt (SBU-178): oltre sparisce il più vecchio.
    static let maxTrees = 3

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

    // MARK: Meteo (SBU-177)

    /// Foglie e petali presi dal cursore: quanto in su e di lato volano via dal mucchio (pt/s).
    static let leafScatterPop: ClosedRange<CGFloat> = 60...220
    static let leafScatterSpread: CGFloat = 120
    /// Di un mucchio di foglie si stacca un pezzo ogni tanti granelli di neve.
    static let leafPieceShare = 3
    /// Foglie e petali in volo: pesano meno della polvere e l'aria li frena di più (`grainGravity`, `grainAirDrag`).
    static let leafGravity: CGFloat = 160
    static let leafAirDrag: CGFloat = 2.5
    /// Petali posati sulle finestre, al massimo per finestra: oltre se ne va il più vecchio.
    static let maxRestingPerPile = 60
    /// L'ultimo tratto della vita di un petalo posato, in cui sfuma (s).
    static let restingFade: CGFloat = 3

    /// Le lucciole cominciano a radunarsi quando il cursore è fermo da `gatherDelay` s; in `gatherRamp` s arrivano
    /// alla forza piena `gatherRate` (frazione della distanza al secondo). Stanno in un anello di `gatherRing` pt.
    /// Un movimento di più di `stillSlop` pt le disperde.
    static let gatherDelay: CGFloat = 1.5
    static let gatherRamp: CGFloat = 4
    static let gatherRate: CGFloat = 0.6
    static let gatherRing: ClosedRange<CGFloat> = 18...70
    static let stillSlop: CGFloat = 4

    /// Quanto tira il cursore fermo le lucciole (0 = niente): Riduci movimento a metà.
    static func gatherPull(still: CGFloat, calm: Bool) -> CGFloat {
        guard still >= gatherDelay else { return 0 }
        return gatherRate * min(1, (still - gatherDelay) / gatherRamp) * (calm ? 0.5 : 1)
    }

    /// Una stella cadente che tocca un bordo si rompe in tante scintille, che vivono `sparkLife` s.
    /// Con Riduci movimento ne nascono un terzo e non volano: si spengono dove sono.
    static let sparksPerBurst = 14
    static let sparkLife: ClosedRange<CGFloat> = 0.5...1.1
    static let sparkSpeed: ClosedRange<CGFloat> = 60...220
    static let sparkGravity: CGFloat = 260

    /// L'arcobaleno dopo la pioggia: entra in `rainbowFadeIn` s, resta, sfuma negli ultimi `rainbowFadeOut`.
    static let rainbowLife: CGFloat = 40
    static let rainbowFadeIn: CGFloat = 4
    static let rainbowFadeOut: CGFloat = 8
    /// Quanto è coprente nel pieno: un velo, non una bandiera.
    static let rainbowOpacity: CGFloat = 0.35

    /// «Meteo a caso»: l'effetto cambia da solo ogni 10–25 minuti, con una dissolvenza di `weatherFade` s per lato.
    static let weatherShuffle: ClosedRange<TimeInterval> = 600...1500
    static let weatherFade: TimeInterval = 1.2

    /// «Mucchi più alti»: l'altezza massima dei mucchi (Impostazioni → Dove si posa) moltiplicata per tanto.
    static let tallSnowFactor: Double = 2.5

    // MARK: Secondo giro meteo (SBU-185)

    /// Vento fisso: le raffiche scendono al massimo a questa parte della forza scelta, senza cambiare lato.
    static let windGustDip: CGFloat = 0.6
    /// «Vento variabile»: gira ogni mezzo periodo (3 minuti), con almeno questa forza anche col cursore a zero (pt/s).
    static let variableWindPeriod: CGFloat = 360
    static let variableWindFloor: CGFloat = 30

    /// Con Risparmio energetico, o con il Mac caldo (`thermalState` da `.serious` in su), metà effetto.
    static func energyShare(lowPower: Bool, thermal: ProcessInfo.ThermalState) -> CGFloat {
        lowPower || thermal == .serious || thermal == .critical ? 0.5 : 1
    }

    /// «Finestre pulite»: la neve su finestre e Dock si scioglie di `cleanMeltRate` pt al secondo
    /// fino a uno strato di `cleanLayer` pt.
    static let cleanLayer: CGFloat = 3
    static let cleanMeltRate: CGFloat = 2

    /// Gli schizzi della pioggia sul bordo di una finestra: poche goccioline basse che durano un attimo.
    /// Solo una goccia del temporale su `1/splashShare` si rompe sul bordo: le altre cadono davanti.
    static let splashDrops = 5
    static let splashShare = 0.35
    static let splashSpeed: ClosedRange<CGFloat> = 40...110
    static let splashLife: ClosedRange<CGFloat> = 0.2...0.45

    /// Il fulmine sull'icona del Dock di un'app che chiudi mentre piove: quanti tratti e quanto resta (s).
    static let boltSegments = 10
    static let boltLife: CGFloat = 0.45
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
    /// Ogni quanto (s) si guarda se è cominciato un altro momento. Solo di ripiego: di solito il cambio
    /// lo fa macOS con lo sfondo dinamico (`DynamicWallpaper`), e questo timer non parte.
    static let momentCheckInterval: TimeInterval = 60
    /// La qualità dei JPEG dei momenti, scritti una volta in Application Support.
    static let momentJPEGQuality = 0.9
    /// La qualità dei fotogrammi dell'HEIC dinamico, scritto una volta per sfondo in Application Support.
    static let dynamicWallpaperQuality = 0.8

    // MARK: Albero da decorare, pupazzo, visitatori (SBU-178)

    /// Le decorazioni su un albero, al massimo (la stella non conta: ce n'è una sola e sostituisce la vecchia).
    static let maxDecorations = 40
    /// Quanto può crescere un albero (1 = come lo pianti) e quanto si ingrandisce o rimpicciolisce una decorazione.
    static let treeGrowth: ClosedRange<CGFloat> = 1...2.2
    static let decorationScale: ClosedRange<CGFloat> = 0.5...2.5
    /// La rotella: un punto di scorrimento ingrandisce dell'1% (con ⇧ o ⌥ gira di un grado).
    static let scrollResize: CGFloat = 0.01

    /// Ogni quanto si salvano alberi e pupazzi (s), se sono cambiati; poi all'uscita e quando si ricreano gli schermi.
    static let keepInterval: TimeInterval = 5

    /// Lo Yeti passa da solo ogni 4–9 minuti, solo se c'è almeno un pupazzo da portare via.
    static let yetiInterval: ClosedRange<CGFloat> = 240...540
    /// Cammina a `yetiWalk` pt/s, scappa a `yetiDash` quando lo scacci; con il pupazzo in spalla va a `yetiCarry`.
    static let yetiWalk: CGFloat = 70
    static let yetiCarry: CGFloat = 55
    static let yetiDash: CGFloat = 320
    /// Il trenino con l'elfo passa da solo ogni 5–10 minuti, a `trainSpeed` pt/s, e lascia un regalo.
    static let trainInterval: ClosedRange<CGFloat> = 300...600
    static let trainSpeed: CGFloat = 130
    /// La lettera sale fino alla slitta a `letterRise` pt/s.
    static let letterRise: CGFloat = 160
    /// Con Riduci movimento la busta compare lassù in `letterFadeIn` s, resta `letterStay` s e svanisce in `letterFadeOut` s.
    static let letterFadeIn: TimeInterval = 0.4
    static let letterStay: TimeInterval = 1.2
    static let letterFadeOut: TimeInterval = 0.6

    /// Lo Yeti prende il pupazzo a meno di `yetiReach` pt; più in alto, a meno di `yetiJumpReach` pt, ci salta sopra
    /// arrivando `yetiJumpClearance` pt più su del pupazzo.
    static let yetiReach: CGFloat = 8
    static let yetiJumpReach: CGFloat = 40
    static let yetiJumpClearance: CGFloat = 24
    /// Dove l'elfo lancia il regalo, in frazioni della larghezza dello schermo (lontano dai bordi).
    static let elfDropSpan: ClosedRange<CGFloat> = 0.15...0.85
    /// Il regalo parte dal vagone a `elfGiftHeight` pt, lanciato indietro a `elfGiftThrow.dx` e in su a `elfGiftThrow.dy` pt/s.
    static let elfGiftHeight: CGFloat = 26
    static let elfGiftThrow = CGVector(dx: 60, dy: 240)
    /// L'altezza (pt dai piedi, albero a grandezza 1) dove l'elfo appende la sua decorazione.
    static let elfDecorationHeight: ClosedRange<CGFloat> = 16...60

    // MARK: Pupazzi vivi (SBU-187)

    /// Una palla o un pupazzo lanciati più forte di così (pt/s) si rompono in neve al primo urto.
    /// Cadere da soli non li rompe: solo il lancio.
    static let shatterThrow: CGFloat = 1000
    /// Quanti granelli di neve lascia una palla rotta (un pupazzo ne lascia tre volte tanti).
    static let shatterGrains = 40
    /// Una finestra scossa fa saltare i pupazzi e le palle che ci stanno sopra (pt/s in su, e un po' di lato).
    static let shakeHop: CGFloat = 380
    static let shakeHopSide: CGFloat = 30
    /// Due pupazzi sullo stesso bordo, a questa distanza (pt), ogni tanto si tirano una palla (Impostazioni → Visitatori).
    static let fightReach: ClosedRange<CGFloat> = 40...260
    static let fightInterval: ClosedRange<CGFloat> = 25...70
    /// Quanto vola la palla tra i due (s).
    static let fightFlight: CGFloat = 0.8
    /// Lo Yeti colpito da una palla cade e sparisce in tanti secondi.
    static let yetiFall: CGFloat = 1.2
    /// Gli elfi passano da soli ogni 1½–3 ore (Impostazioni → Visitatori). Escono dalla neve in `elfRise` s,
    /// rotolano una palla ogni `elfRollInterval` s a `elfBallGap` pt l'una dall'altra, poi se ne vanno a `elfWalk` pt/s.
    static let elvesInterval: ClosedRange<CGFloat> = 5400...10_800
    static let elfRise: CGFloat = 0.5
    static let elfRollInterval: CGFloat = 1
    static let elfBallGap: CGFloat = 14
    static let elfWalk: CGFloat = 60

    // MARK: Decora (SBU-187)

    /// Le decorazioni sulla scrivania, per schermo: oltre sparisce la più vecchia.
    static let maxDeskItems = 12
    /// Quanto si ingrandisce o rimpicciolisce una decorazione.
    static let deskScale: ClosedRange<CGFloat> = 0.5...3
    /// Le luci pendono in mezzo di questa parte della loro lunghezza, almeno `lightsMinSag` pt.
    static let lightsSag: CGFloat = 0.18
    static let lightsMinSag: CGFloat = 12
    /// Un'estremità delle luci si prende entro tanti pt; le lampadine sono a `bulbGap` pt l'una dall'altra.
    static let lightsGrab: CGFloat = 14
    static let bulbRadius: CGFloat = 4
    static let bulbGap: CGFloat = 18
    /// Fiamme e lampadine si ridisegnano tante volte al secondo: bastano, e costano poco.
    static let deskFlickerFPS: Double = 8

    // MARK: Luci in alto (SBU-229)

    /// Il filo sotto la barra dei menu: un gancio ogni `topLightsSpan` pt circa, e in mezzo pende di `topLightsSag` pt.
    static let topLightsSpan: CGFloat = 180
    static let topLightsSag: CGFloat = 12
    /// Una lampadina ogni `topLightsBulbGap` pt almeno, grande `topLightsBulbRadius`; la finestra è alta `topLightsHeight`.
    static let topLightsBulbGap: CGFloat = 32
    static let topLightsBulbRadius: CGFloat = 5
    static let topLightsHeight: CGFloat = 44
    /// Spenta a metà animazione una lampadina resta a questa luce, non nera.
    static let topLightsDim: CGFloat = 0.3
    /// A turno: una ogni `topLightsChaseGroup` accesa, il turno passa alla vicina ogni `topLightsChaseStep` s.
    static let topLightsChaseGroup = 3
    static let topLightsChaseStep = 0.5
    /// Lampeggio lento: un respiro ogni `topLightsBlinkPeriod` s. Onda: un giro ogni `topLightsWavePeriod` s, lunga
    /// `topLightsWaveLength` lampadine.
    static let topLightsBlinkPeriod = 3.0
    static let topLightsWavePeriod = 2.5
    static let topLightsWaveLength = 10.0
    /// Si ridisegnano tante volte al secondo, solo se l'animazione si muove.
    static let topLightsFPS: Double = 15

    // MARK: Mandare un oggetto (SBU-200)

    /// Un file `.sbuseasons` più grande non si legge: un albero pieno di decorazioni ne occupa meno di 10 KB.
    static let toyFileMaxBytes = 64 * 1024
    /// Le luci ricevute sono lunghe al massimo tanti pt, in larghezza e in altezza (il file non è fidato).
    static let toyFileMaxLightsSpan: CGFloat = 1600
    /// Una decorazione ricevuta compare piano, in tanti secondi (solo opacità: va bene anche con Riduci movimento).
    static let receivedFadeIn: TimeInterval = 0.8
    /// Per quanti secondi la decorazione ricevuta resta sopra le finestre prima di tornare sulla scrivania (SBU-205).
    static let receivedOnTop: TimeInterval = 4
}
