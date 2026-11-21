import AppKit
import SpriteKit

/// La scena SpriteKit che disegna e muove le particelle della stagione (i "fiocchi").
///
/// Coordinate: origine in basso a sinistra (come SpriteKit e come `NSEvent.mouseLocation`),
/// un punto della scena = un punto dello schermo.
final class SeasonScene: SKScene {

    // MARK: - Stato

    private struct Flake {
        let node: SKSpriteNode
        let radius: CGFloat
        /// 0 = lontano (piccolo, lento, trasparente) … 1 = vicino (grande, veloce, opaco).
        let depth: CGFloat
        let fallSpeed: CGFloat
        let swayAmplitude: CGFloat
        let swayFrequency: CGFloat
        let phase: CGFloat
        let spin: CGFloat
        let flip: CGFloat
        let alpha: CGFloat
        let drift: CGFloat
        let bob: CGFloat
        let pulse: CGFloat
        let gap: CGFloat
        /// Mezza diagonale lunga del disegno: quando è del tutto fuori dallo schermo.
        let extent: CGFloat
        /// Velocità extra impressa dal cursore, si smorza nel tempo.
        var push: CGVector = .zero
    }

    /// I fiocchi della nevicata: quando arrivano in fondo (o si posano) rinascono in cima.
    private var flakes: [Flake] = []
    /// Neve staccata da un mucchio (dal cursore o da una finestra che si muove): si sbriciola
    /// in granelli che cadono per gravità, come polvere, e spariscono quando si posano o escono.
    private struct Grain {
        let node: SKSpriteNode
        var velocity: CGVector
        /// Il mucchio da cui è partito: non ci ricade sopra, scende davanti alla finestra.
        let source: Pile?
    }
    private var grains: [Grain] = []

    /// Neve posata sulle finestre, per ID di finestra. `rect` è in coordinate della scena.
    private var piles: [CGWindowID: (pile: Pile, rect: CGRect)] = [:]
    /// Neve posata sopra il Dock. `rect` è in coordinate della scena.
    private var dock: (pile: Pile, rect: CGRect)?
    /// La stagione: forma, colore e caduta dei fiocchi, colore dei mucchi.
    private(set) var season: any Season
    private var flakeTexture: SKTexture
    private let screenOrigin: CGPoint

    private var lastUpdateTime: TimeInterval?
    private(set) var elapsed: CGFloat = 0
    private var lastMouse: CGPoint?
    /// Tempo dall'ultimo aggiornamento dei mucchi (frana + ridisegno).
    private var pileClock: CGFloat = 0

    /// Gli oggetti con cui giocare, nell'ordine in cui si disegnano (l'ultimo è davanti).
    private(set) var toys: [Toy] = []
    /// Dove possono stare in piedi gli oggetti: i tratti scoperti dei bordi e il Dock (senza il fondo).
    private(set) var ledges: [Ledge] = []
    /// Dove comincia la barra dei menu (coordinate della scena): un oggetto non sta in piedi dove la coprirebbe.
    private(set) var ceiling: CGFloat?
    /// L'oggetto in mano al cursore: dove l'ha preso, dov'è partito, l'ultima posizione e la velocità del lancio.
    /// `part`: si trascina una parte dell'oggetto (una decorazione), non l'oggetto.
    private var held: (toy: Toy, grip: CGVector, start: CGPoint, last: CGPoint, time: TimeInterval, velocity: CGVector,
                       part: Bool)?
    private var pointerShake = ShakeDetector()
    /// Granelli di neve raccolti con ⌥ per la prossima palla.
    private var gathered = 0
    /// Quando è stata scossa l'ultima volta la palla di vetro (tempo della scena).
    private var lastGlobe = -CGFloat.infinity
    /// Quando due pupazzi vicini si tirano la prossima palla (tempo della scena, `LivelySnowmen`).
    var nextFight: CGFloat?

    /// Nebbia, nuvole e lampi della stagione.
    let sky = Sky()
    /// Le gocce sul vetro della stagione.
    let glass = Glass()
    /// La notte: schermo più scuro e la candela (Impostazioni → Notte). Si ricontrolla una volta al secondo.
    let night = Night()
    private var nightClock: CGFloat = .infinity

    /// Natale (`Toys/Christmas/`): che giorno è e il diario dei regali, la slitta in volo.
    /// Quando passa e su quali schermi lo decide `Passages`, uno per tutti gli schermi.
    var christmas = ChristmasClock()
    var santa: Santa?
    /// I passaggi di Babbo Natale su questo schermo (dal menu o da solo).
    var santaVisits = 0
    /// La slitta è uscita di lato, alla quota (della scena) data: `Passages` la fa entrare nello schermo dopo.
    var onSantaLeft: ((CGFloat) -> Void)?
    /// Il trenino con l'elfo in corsa (`Toys/Visitors/`); lo Yeti invece è un oggetto, sta in `toys`.
    var train: Train?
    /// La busta della letterina a Babbo Natale, finché la slitta non la prende (`Toys/Christmas/Letter.swift`).
    var letter: SKSpriteNode?
    /// Yeti o trenino usciti di lato: `Visitors` li fa entrare nello schermo dopo.
    var onVisitorLeft: ((VisitorKind, VisitorExit) -> Void)?

    /// Lo schermo, in coordinate globali (come `NSScreen.frame`).
    var screenFrame: CGRect { CGRect(origin: screenOrigin, size: size) }
    /// Dove può volare la slitta, in coordinate globali: lo schermo sotto la barra dei menu.
    var flightBand: CGRect { CGRect(x: screenOrigin.x, y: screenOrigin.y, width: size.width, height: ceiling ?? size.height) }

    /// "Metti in pausa i giochi": gli oggetti stanno fermi dove sono e non si prendono col mouse;
    /// la slitta in volo sparisce (non resta ferma in cielo) e non ne parte un'altra finché non si toglie.
    var toysPaused = false {
        didSet {
            guard toysPaused else { return }
            dropHeld()
            santa?.node.removeFromParent()
            santa = nil
            letter?.removeFromParent()
            letter = nil
            removeVisitors()
        }
    }

    /// "Riduci movimento" di macOS: metà dei fiocchi, niente vento, oscillazione, rotazione, lanci o rimbalzi.
    var reduceMotion = false {
        didSet {
            guard reduceMotion != oldValue else { return }
            // Senza particelle (nebbia, nuvole) `rebuildFlakes` non serve, ma i banchi vanno ricontati lo stesso.
            if flakes.isEmpty { sky.set(season, size: size, amount: skyAmount) } else { rebuildFlakes() }
        }
    }

    /// Quantità e dimensione con cui sono stati creati i fiocchi attuali:
    /// se nelle impostazioni cambiano, li ricreiamo.
    private var builtWith: (count: Double, size: Double)?

    // MARK: - Init

    init(size: CGSize, screenOrigin: CGPoint, season: any Season) {
        self.screenOrigin = screenOrigin
        self.season = season
        flakeTexture = season.makeTexture()
        super.init(size: size)
        backgroundColor = .clear
        anchorPoint = .zero
        scaleMode = .resizeFill
        addChild(sky)
        addChild(glass)
        addChild(night)
        glass.set(season.glass)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) non supportato")
    }

    override func didMove(to view: SKView) {
        rebuildFlakes()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        if !flakes.isEmpty && oldSize != size {
            rebuildFlakes()
        }
    }

    // MARK: - Stagione

    /// Cambia stagione: i fiocchi rinascono con la forma nuova, i mucchi prendono il colore nuovo.
    /// La stessa stagione di nuovo non fa niente: i fiocchi non saltano.
    func setSeason(_ season: any Season) {
        guard season.id != self.season.id else { return }
        self.season = season
        flakeTexture = season.makeTexture()
        for grain in grains {
            grain.node.texture = flakeTexture
            grain.node.color = season.pileColor
        }
        for pile in everyPile { pile.node.fillColor = season.pileColor }
        if !(season is Snow) {
            meltSnowToys()
            removeWinterPlay(includingCableCar: true)
            removeChristmas()
            removeFigures()
            removeVisitors()
        }
        if !season.settles { everyPile.forEach { $0.clear() } }
        // La pausa è una voce dei giochi d'inverno: fuori dall'inverno non si potrebbe togliere (QA SBU-63).
        toysPaused = false
        gathered = 0
        glass.set(season.glass)
        rebuildFlakes()
    }

    // MARK: - Fiocchi

    /// Ricrea le particelle. `keeping`: tiene quelle che ci sono e ne toglie o ne aggiunge (in cima) fino al numero
    /// giusto: così il cursore dell'intensità non fa saltare quelle che stanno cadendo.
    private func rebuildFlakes(keeping: Bool = false) {
        if !keeping {
            flakes.forEach { $0.node.removeFromParent() }
            flakes = []
        }
        let settings = Settings.shared.values
        builtWith = (settings.flakeCount, settings.flakeSize)
        sky.set(season, size: size, amount: skyAmount)
        guard size.width > 0, size.height > 0 else {
            flakes.forEach { $0.node.removeFromParent() }
            flakes = []
            return
        }
        let calm = reduceMotion ? Tuning.reducedMotionFlakes : 1
        let exact = settings.flakeCount * season.abundance * Double(size.width * size.height / Tuning.referenceScreenArea * calm)
        let count = season.abundance > 0 ? max(Int(exact), 1) : 0
        if flakes.count > count {
            flakes[count...].forEach { $0.node.removeFromParent() }
            flakes.removeLast(flakes.count - count)
        }
        while flakes.count < count {
            var flake = makeFlake(at: CGPoint(x: .random(in: 0...size.width), y: .random(in: 0...size.height)))
            // Chi aspetta il suo turno (le stelle) e chi arriva dopo partono da sopra lo schermo.
            if keeping || flake.gap > 0 { respawn(&flake) }
            flakes.append(flake)
        }
    }

    /// L'intensità rispetto a "Media": banchi e gocce sul vetro la seguono come le particelle.
    private var intensity: CGFloat { CGFloat(Settings.shared.values.flakeCount / SnowSettings().flakeCount) }

    /// Quanti banchi rispetto a "Media": seguono l'intensità, e con Riduci movimento sono la metà.
    private var skyAmount: CGFloat { intensity * (reduceMotion ? Tuning.reducedMotionFlakes : 1) }

    /// Crea un fiocco nel punto indicato.
    private func makeFlake(at position: CGPoint) -> Flake {
        let depth = CGFloat.random(in: 0...1)
        let particle = season.particle(depth: depth)
        let radius = particle.radius * Settings.shared.values.flakeSize

        let node = SKSpriteNode(texture: flakeTexture)
        node.size = CGSize(width: radius * 2, height: radius * 2)
        node.alpha = particle.alpha
        node.zPosition = depth
        node.position = position
        if particle.length != 1 { node.size.width *= particle.length }
        if particle.drift != 0 { node.zRotation = atan2(-particle.fallSpeed, particle.drift) }
        if let tint = particle.tint {
            node.color = tint
            node.colorBlendFactor = 1
        }
        addChild(node)

        return Flake(
            node: node,
            radius: radius,
            depth: depth,
            fallSpeed: particle.fallSpeed,
            swayAmplitude: particle.swayAmplitude,
            swayFrequency: particle.swayFrequency,
            phase: .random(in: 0...(2 * .pi)),
            spin: particle.spin * 2 * .pi,
            flip: particle.flip * 2 * .pi,
            alpha: particle.alpha,
            drift: particle.drift,
            bob: particle.bob,
            pulse: particle.pulse * 2 * .pi,
            gap: particle.gap,
            extent: max(node.size.width, node.size.height) / 2
        )
    }

    private func respawn(_ flake: inout Flake) {
        // Chi va di traverso comincia ad andarci a `extent` sopra lo schermo (vedi `move`): parte spostato
        // all'indietro di quel tratto. Una stella (più di lato che in giù) entra dal bordo in alto, nei 7/10
        // da cui arriva: attraversa il cielo. La pioggia obliqua entra anche da sopra il lato da cui viene,
        // così copre tutto lo schermo.
        let slope = flake.drift / max(flake.fallSpeed, 1)
        let lead = slope * flake.extent
        let travel = slope * size.height
        let entry: ClosedRange<CGFloat> = abs(slope) <= 1 ? min(0, -travel)...max(size.width, size.width - travel)
            : flake.drift > 0 ? 0...(size.width * 0.7) : (size.width * 0.3)...size.width
        flake.node.position = CGPoint(
            x: .random(in: entry) - lead,
            y: size.height + flake.extent + .random(in: 0...40) + .random(in: 0...max(flake.gap, 0))
        )
        flake.push = .zero
    }

    /// Fa partire granelli di polvere dai punti indicati: quasi fermi, con una piccola spinta
    /// orizzontale (`drift` ± `spread`) e un saltello verticale (`pop`). Poi ci pensa la gravità.
    private func spawnPowder(_ points: [CGPoint], from source: Pile? = nil, drift: CGFloat = 0,
                             spread: CGFloat = 8, pop: ClosedRange<CGFloat> = -5...5) {
        for point in points where grains.count < Tuning.maxGrains {
            let node = SKSpriteNode(texture: flakeTexture)
            let diameter = CGFloat.random(in: 2...4)   // più piccoli dei fiocchi: è polvere
            node.size = CGSize(width: diameter, height: diameter)
            node.alpha = .random(in: 0.8...1)
            // È un pezzo del mucchio: ha il suo colore (una foglia senza tinta sarebbe bianca).
            node.color = season.pileColor
            node.colorBlendFactor = 1
            node.zPosition = 1.5
            node.position = point
            addChild(node)
            grains.append(Grain(node: node, velocity: CGVector(dx: drift + .random(in: -spread...spread),
                                                               dy: .random(in: pop)), source: source))
        }
    }

    var flakeCount: Int { flakes.count }
    var grainCount: Int { grains.count }
    /// Il granello più in alto (0 se non ce ne sono).
    var highestGrain: CGFloat { grains.map(\.node.position.y).max() ?? 0 }
    /// La neve posata su una finestra.
    func pile(for id: CGWindowID) -> Pile? { piles[id]?.pile }
    /// La neve posata sul Dock.
    var dockPile: Pile? { dock?.pile }
    /// Il bordo del Dock su cui stanno gli oggetti.
    var dockLedge: Ledge? { dock.map { Ledge(y: $0.rect.maxY, span: $0.rect.minX...$0.rect.maxX) } }
    /// Tutti i mucchi: finestre e Dock.
    var everyPile: [Pile] { piles.values.map(\.pile) + (dock.map { [$0.pile] } ?? []) }

    // MARK: - Oggetti

    func add(_ toy: Toy) {
        toys.append(toy)
        addChild(toy.node)
    }

    func remove(_ toy: Toy) {
        toys.removeAll { $0 === toy }
        toy.node.removeFromParent()
        if held?.toy === toy { held = nil }
    }

    /// L'oggetto sotto il punto, il più in primo piano.
    func toy(at point: CGPoint) -> Toy? {
        toys.last { $0.frame.contains(point) }
    }

    /// La finestra deve prendere il mouse? Solo sopra un oggetto, o mentre se ne trascina uno:
    /// altrove i clic passano alle app sotto (README, "Clic sugli oggetti").
    func wantsMouse(at point: CGPoint) -> Bool {
        !toysPaused && (held != nil || toy(at: point) != nil)
    }
    /// L'oggetto in mano al cursore, se c'è.
    var heldToy: Toy? { held?.toy }
    /// `wantsMouse` nel punto del cursore, ricalcolato a ogni passo.
    private(set) var wantsMouse = false

    /// Pressione del mouse: prende l'oggetto sotto il punto. false = non c'è niente.
    @discardableResult
    func grab(at point: CGPoint, time: TimeInterval) -> Bool {
        guard !toysPaused, let toy = toy(at: point) else { return false }
        let feet = toy.body.position
        let grip = CGVector(dx: point.x - feet.x, dy: point.y - feet.y)
        let part = toy.pressPart(at: CGPoint(x: grip.dx, y: grip.dy))
        held = (toy, grip, point, point, time, .zero, part)
        if !part && toy.isDraggable {
            toy.body.hold(at: feet)
            toy.thrownHard = false
        }
        // Davanti agli altri oggetti.
        toys.removeAll { $0 === toy }
        toys.append(toy)
        toy.node.zPosition = 2 + CGFloat(toys.count) * 0.001
        return true
    }

    func drag(to point: CGPoint, time: TimeInterval) {
        guard var held else { return }
        let dt = time - held.time
        if dt > 0 {
            // Media mobile: il lancio segue gli ultimi movimenti, non solo l'ultimo scatto.
            let now = CGVector(dx: (point.x - held.last.x) / dt, dy: (point.y - held.last.y) / dt)
            held.velocity = CGVector(dx: held.velocity.dx * 0.3 + now.dx * 0.7, dy: held.velocity.dy * 0.3 + now.dy * 0.7)
        }
        held.last = point
        held.time = time
        self.held = held
        let feet = held.toy.body.position
        if held.part {
            held.toy.dragPart(to: CGPoint(x: point.x - feet.x, y: point.y - feet.y))
        } else if held.toy.isDraggable {
            held.toy.body.hold(at: CGPoint(x: point.x - held.grip.dx, y: point.y - held.grip.dy))
            held.toy.node.position = held.toy.body.position
        }
    }

    /// Rilascio: un clic se il mouse non si è quasi mosso, se no un lancio (con Riduci movimento cade dritto).
    func letGo(at point: CGPoint, time: TimeInterval) {
        // Fermo da un po' prima di lasciarlo: nessun lancio. Va letto prima di `drag`, che aggiorna `held.time`.
        let stale = held.map { time - $0.time > 0.1 } ?? false
        drag(to: point, time: time)
        guard let held else { return }
        self.held = nil
        let isClick = hypot(point.x - held.start.x, point.y - held.start.y) < Tuning.clickSlop
        if held.part {
            let feet = held.toy.body.position
            held.toy.releasePart(at: CGPoint(x: point.x - feet.x, y: point.y - feet.y))
            return
        }
        guard held.toy.isDraggable else {
            if isClick { held.toy.clicked(at: CGPoint(x: point.x - held.toy.body.position.x, y: point.y - held.toy.body.position.y)) }
            return
        }
        held.toy.body.release(velocity: isClick || stale || reduceMotion ? .zero : held.velocity)
        let thrown = held.toy.body.velocity
        held.toy.thrownHard = held.toy.breaks && hypot(thrown.dx, thrown.dy) >= Tuning.shatterThrow
        if held.toy is Snowball, held.toy.body.velocity != .zero { SoundBoard.shared.play("palla-di-neve-lancio") }
        if isClick {
            let feet = held.toy.body.position
            held.toy.clicked(at: CGPoint(x: point.x - feet.x, y: point.y - feet.y))
        }
    }

    /// Il cursore si è mosso su questo schermo: se è stato scosso, lo sanno tutti gli oggetti.
    /// La neve si ferma mentre trascini: l'oggetto cade lì, e la finestra non resta col mouse preso.
    func dropHeld() {
        if let held, !held.part, held.toy.isDraggable { held.toy.body.release(velocity: .zero) }
        if let held, held.part { held.toy.releasePart(at: CGPoint(x: held.grip.dx, y: held.grip.dy)) }
        held = nil
    }

    // MARK: - Schede, pizzico, rotella (SBU-178)

    /// La scheda di un oggetto (pupazzo, albero) da aprire nel punto dato, in coordinate globali.
    /// La apre `OverlayWindow` (`ToyCard`); i test la intercettano.
    var onCard: ((Toy, CGPoint) -> Void)?

    /// Chiede la scheda di `toy`, aperta sopra il punto `point` della scena (di norma il cursore).
    func openCard(for toy: Toy, at point: CGPoint) {
        guard !toysPaused else { return }
        onCard?(toy, CGPoint(x: point.x + screenOrigin.x, y: point.y + screenOrigin.y))
    }

    /// Clic destro (o ⌃ clic) su un oggetto: la sua scheda, se ne ha una.
    func secondaryClick(at point: CGPoint) {
        guard !toysPaused, let toy = toy(at: point) else { return }
        if let tree = toy as? ChristmasTree {
            let feet = tree.body.position
            tree.cardFocus = tree.look.decoration(at: CGPoint(x: (point.x - feet.x) / tree.look.growth,
                                                              y: (point.y - feet.y) / tree.look.growth))
        }
        openCard(for: toy, at: point)
    }

    /// Pizzico o rotella sopra un oggetto: lo ingrandisce o rimpicciolisce (o una sua parte).
    func resize(at point: CGPoint, by factor: CGFloat) {
        guard !toysPaused, factor > 0, let toy = toy(at: point) else { return }
        toy.resized(at: CGPoint(x: point.x - toy.body.position.x, y: point.y - toy.body.position.y), by: factor)
    }

    /// Rotazione a due dita (o ⇧ e la rotella) sopra un oggetto.
    func turn(at point: CGPoint, by radians: CGFloat) {
        guard !toysPaused, let toy = toy(at: point) else { return }
        toy.turned(at: CGPoint(x: point.x - toy.body.position.x, y: point.y - toy.body.position.y), by: radians)
    }

    /// `rolling`: ⌥ premuto d'inverno, si sta facendo una palla. Passare avanti e indietro sulla neve
    /// per raccoglierla non è una scossa: se no la palla di vetro porterebbe via la neve (SBU-60).
    func pointerMoved(to point: CGPoint, time: TimeInterval, rolling: Bool = false) {
        guard !rolling, pointerShake.add(point, at: time) else { return }
        shakeGlobe()
        toys.forEach { $0.shaken(.pointer) }
    }

    /// Finestre scosse (le riconosce `AppDelegate`, una volta per tutti gli schermi).
    func windowsShaken(_ ids: Set<CGWindowID>) {
        if !ids.isEmpty { shakeGlobe() }
        for id in ids {
            toys.forEach { $0.shaken(.window(id)) }
            // Palle e pupazzi sopra la finestra scossa saltano (SBU-187); con Riduci movimento no.
            guard !reduceMotion, !toysPaused, let entry = piles[id] else { continue }
            for toy in riders(of: entry.pile.baseY, span: entry.rect.minX...entry.rect.maxX) where toy.breaks {
                toy.body.velocity = CGVector(dx: .random(in: -Tuning.shakeHopSide...Tuning.shakeHopSide), dy: Tuning.shakeHop)
            }
        }
    }

    /// Gli oggetti fermi in piedi sul bordo all'altezza `y`, dentro `span` (quelli in mano no).
    private func riders(of y: CGFloat, span: ClosedRange<CGFloat>) -> [Toy] {
        toys.filter { $0.body.isResting && !$0.body.isHeld && abs($0.body.position.y - y) < 0.5 && span.contains($0.body.position.x) }
    }

    /// Una palla o un pupazzo lanciati forte si rompono: spariscono in neve che cade e si posa (SBU-187).
    func shatter(_ toy: Toy) {
        let frame = toy.frame
        let count = Tuning.shatterGrains * (toy is Snowman ? 3 : 1)
        let points = (0..<count).map { _ in
            CGPoint(x: .random(in: frame.minX...frame.maxX), y: .random(in: frame.minY...frame.maxY))
        }
        remove(toy)
        spawnPowder(points, spread: 70, pop: 40...220)
        SoundBoard.shared.play("palla-di-neve-colpo")
    }

    // MARK: - Palle di neve e pupazzo

    /// ⌥ e il cursore passa sulla neve posata: la neve raccolta sparisce dal mucchio e, quando basta, diventa
    /// una palla sotto il cursore. Solo d'inverno.
    func roll(at point: CGPoint) {
        guard season is Snow else { return }
        gathered += everyPile.reduce(0) { $0 + $1.scoop(at: point, radius: Tuning.scoopRadius).count }
        guard gathered >= Tuning.snowballSnow else { return }
        gathered = 0
        makeSnowball(at: point)
        SoundBoard.shared.play("passo-neve")   // la neve stretta scricchiola come sotto i passi
    }

    @discardableResult
    func makeSnowball(at point: CGPoint) -> Snowball {
        let ball = Snowball(at: point)
        add(ball)
        let balls = toys.compactMap { $0 as? Snowball }
        balls.prefix(max(0, balls.count - Tuning.maxSnowballs)).forEach(remove)   // via le più vecchie
        return ball
    }

    /// "Togli le palle di neve": le palle sciolte, non i pupazzi.
    func clearSnowballs() {
        toys.filter { $0 is Snowball }.forEach(remove)
    }

    private func meltSnowToys() {
        toys.filter { $0 is Snowball || $0 is Snowman }.forEach(remove)
    }

    /// Tre palle ferme e vicine (non in mano) diventano un pupazzo, dove stava quella al centro.
    private func buildSnowman() {
        let balls = toys.compactMap { $0 as? Snowball }.filter { $0.body.isResting && held?.toy !== $0 }
        guard balls.count >= 3,
              let trio = snowmanTrio(balls.map(\.body.position), within: Tuning.snowmanReach)?.map({ balls[$0] })
        else { return }
        let feet = trio.map(\.body.position)
        trio.forEach(remove)
        add(Snowman(at: CGPoint(x: feet.map(\.x).reduce(0, +) / 3, y: feet.map(\.y).max() ?? 0)))
        SoundBoard.shared.play("pupazzo")
    }

    // MARK: - Palla di vetro

    /// Il cursore o una finestra scossi: tutta la neve posata si alza, i fiocchi salgono, le palle saltano;
    /// poi ricade. Con Riduci movimento no. Dopo una scossa riposa qualche secondo (`Tuning.globeRest`).
    /// Chiamato a ogni scossa, anche quella che la palla di vetro ignora: il tour spunta "Scuoti il cursore".
    var onGlobeShaken: (() -> Void)?

    func shakeGlobe() {
        onGlobeShaken?()   // anche con Riduci movimento: è il gesto che conta
        guard !reduceMotion, elapsed - lastGlobe >= Tuning.globeRest else { return }
        lastGlobe = elapsed
        for pile in everyPile { spawnPowder(pile.releaseAll(), spread: 90, pop: Tuning.globeLift) }
        for i in flakes.indices {
            flakes[i].push.dx += .random(in: -90...90)
            flakes[i].push.dy += .random(in: Tuning.globeLift)
        }
        for ball in toys where ball is Snowball && ball.body.isResting {
            ball.body.velocity.dy = Tuning.globeLift.lowerBound
        }
        SoundBoard.shared.play("palla-di-vetro")
    }

    override func mouseDown(with event: NSEvent) {
        if event.modifierFlags.contains(.control) { return secondaryClick(at: event.location(in: self)) }
        grab(at: event.location(in: self), time: event.timestamp)
    }
    override func rightMouseDown(with event: NSEvent) { secondaryClick(at: event.location(in: self)) }
    override func magnify(with event: NSEvent) { resize(at: event.location(in: self), by: 1 + event.magnification) }
    override func rotate(with event: NSEvent) { turn(at: event.location(in: self), by: CGFloat(event.rotation) * .pi / 180) }
    override func scrollWheel(with event: NSEvent) { scrollWheel(at: event.location(in: self), with: event) }
    /// La rotella nel punto `point` della scena: ingrandisce; con ⇧ o ⌥ gira.
    func scrollWheel(at point: CGPoint, with event: NSEvent) {
        let step: CGFloat = event.hasPreciseScrollingDeltas ? 1 : 10
        if event.modifierFlags.contains(.shift) || event.modifierFlags.contains(.option) {
            // Con ⇧ macOS manda la rotella del mouse come scorrimento orizzontale.
            let raw = event.scrollingDeltaY != 0 ? event.scrollingDeltaY : event.scrollingDeltaX
            turn(at: point, by: raw * step * .pi / 180)
        } else {
            resize(at: point, by: exp(event.scrollingDeltaY * step * Tuning.scrollResize))
        }
    }
    override func mouseDragged(with event: NSEvent) { drag(to: event.location(in: self), time: event.timestamp) }
    override func mouseUp(with event: NSEvent) { letGo(at: event.location(in: self), time: event.timestamp) }

    // MARK: - Finestre

    /// Riceve finestre e Dock attuali (coordinate globali) e aggiorna i mucchi di neve.
    /// `ceiling`: dove finisce la zona libera dello schermo, sotto la barra dei menu (coordinate della scena).
    func updateWindows(_ edges: [WindowEdge], dock dockFrame: CGRect?, ceiling: CGFloat) {
        self.ceiling = ceiling
        updateDock(dockFrame)
        let maxPile = CGFloat(Settings.shared.values.maxPile)
        var seen = Set<CGWindowID>()
        ledges = dockLedge.map { [$0] } ?? []
        for edge in edges {
            let r = edge.rect.offsetBy(dx: -screenOrigin.x, dy: -screenOrigin.y)
            // Solo bordi su questo schermo, con il mucchio sotto la barra dei menu (decisione di Matteo, MGS-416).
            guard r.maxY > 0, r.maxX > 0, r.minX < size.width,
                  let base = pileBase(edgeTop: r.maxY, pileHeight: maxPile, ceiling: ceiling) else { continue }
            seen.insert(edge.id)
            let open = edge.visible.map { ($0.lowerBound - screenOrigin.x)...($0.upperBound - screenOrigin.x) }
            // Gli oggetti stanno dove si posa la neve: sui tratti scoperti, sotto la barra dei menu.
            ledges += open.map { Ledge(y: base, span: $0) }

            if let old = piles[edge.id], old.rect.minX == r.minX, old.pile.baseY == base, old.rect.width == r.width,
               old.pile.cornerRadius == edge.cornerRadius {
                // Ferma: aggiorna solo i tratti coperti/scoperti.
                spawnPowder(old.pile.setOpen(open), from: old.pile)
            } else {
                let pile = Pile(minX: r.minX, width: r.width, baseY: base, cornerRadius: edge.cornerRadius,
                                maxHeight: maxPile, color: season.pileColor)
                if let old = piles[edge.id] {
                    let shift = CGVector(dx: r.minX - old.rect.minX, dy: r.minY - old.rect.minY)
                    if old.rect.size == r.size, old.pile.cornerRadius == edge.cornerRadius,
                       hypot(shift.dx, shift.dy) <= Tuning.slideOffDistance {
                        // Spostata piano: la neve resta sopra e la segue, e con lei chi ci sta in piedi (SBU-187).
                        for toy in riders(of: old.pile.baseY, span: old.rect.minX...old.rect.maxX) {
                            toy.body.position.x += shift.dx
                            toy.body.position.y = base
                            toy.node.position = toy.body.position
                        }
                        pile.carry(old.pile)
                        old.pile.node.removeFromParent()
                    } else {
                        // Spostata veloce, ridimensionata (o scoperto il raggio giusto): la neve scivola giù.
                        // Un po' di slancio nel verso della finestra.
                        drop(old.pile, drift: max(-200, min(200, shift.dx / Tuning.windowRefreshInterval * 0.25)))
                    }
                }
                spawnPowder(pile.setOpen(open), from: pile)
                pile.redrawIfNeeded()   // subito: se no la neve portata sparisce fino al prossimo ridisegno
                addChild(pile.node)
                piles[edge.id] = (pile, r)
            }
        }
        for (id, entry) in piles where !seen.contains(id) {
            drop(entry.pile)
            piles[id] = nil
        }
    }

    private func updateDock(_ frame: CGRect?) {
        // Il Dock deve stare su questo schermo e in basso (nascosto o di lato: niente neve).
        // Il bordo superiore va abbassato di `dockInset` per combaciare con la barra visibile.
        let inset = CGFloat(Settings.shared.values.dockInset)
        let r = frame.map { CGRect(x: $0.minX - screenOrigin.x, y: $0.minY - screenOrigin.y,
                                   width: $0.width, height: $0.height - inset) }
        let onThisScreen = r.map { $0.minY >= -1 && $0.minY < 20 && $0.midX > 0 && $0.midX < size.width && $0.width > $0.height } ?? false
        if let r, onThisScreen, dock?.rect == r { return }   // fermo: niente da fare
        if let old = dock { drop(old.pile) }                 // spostato/ridimensionato/sparito: la neve cade
        dock = nil
        guard let r, onThisScreen else { return }
        let pile = Pile(minX: r.minX, width: r.width, baseY: r.maxY, cornerRadius: Tuning.dockCornerRadius,
                        maxHeight: CGFloat(Settings.shared.values.maxPile) * Tuning.dockPileFactor, color: season.pileColor)
        addChild(pile.node)
        dock = (pile, r)
    }

    private func drop(_ pile: Pile, drift: CGFloat = 0) {
        spawnPowder(pile.releaseAll(), drift: drift)
        pile.node.removeFromParent()
    }

    /// "Togli quello che si è posato": svuota tutti i mucchi.
    /// Anche le palle di neve e i pupazzi.
    func meltAll() {
        everyPile.forEach { $0.clear() }
        meltSnowToys()
    }

    // MARK: - Loop

    /// Un passo della simulazione. Lo chiama il display link della finestra, non SpriteKit (vedi `OverlayWindow`).
    func step(at currentTime: TimeInterval) {
        // dt limitato: dopo una pausa o un rallentamento non vogliamo salti enormi.
        let dt = CGFloat(min(currentTime - (lastUpdateTime ?? currentTime), 1.0 / 20.0))
        lastUpdateTime = currentTime
        guard dt > 0 else { return }
        elapsed += dt

        // Le impostazioni si leggono una volta per frame: le modifiche dalla finestra si vedono subito.
        let settings = Settings.shared.values
        if let built = builtWith, built != (settings.flakeCount, settings.flakeSize) {
            rebuildFlakes(keeping: built.size == settings.flakeSize)
        }
        let cursorRadius = CGFloat(settings.cursorRadius)
        let cursorRepel = CGFloat(settings.cursorRepel)
        let fallSpeed = CGFloat(settings.fallSpeed)

        // Vento globale che cambia lentamente.
        let maxWind = reduceMotion ? 0 : CGFloat(settings.wind)
        let wind = sin(elapsed * 0.11) * maxWind + sin(elapsed * 0.37) * maxWind * 0.3

        // Posizione e velocità del cursore in coordinate della scena.
        let global = NSEvent.mouseLocation
        let mouse = CGPoint(x: global.x - screenOrigin.x, y: global.y - screenOrigin.y)
        var mouseVelocity = CGVector.zero
        if let last = lastMouse {
            mouseVelocity = CGVector(dx: (mouse.x - last.x) / dt, dy: (mouse.y - last.y) / dt)
        }
        lastMouse = mouse
        let onScreen = CGRect(origin: .zero, size: size).contains(mouse)
        // ⌥ d'inverno: il cursore raccoglie la neve per una palla, invece di spazzarla o scuotere la palla di vetro.
        let rolling = onScreen && season is Snow && NSEvent.modifierFlags.contains(.option)
        if onScreen { pointerMoved(to: mouse, time: currentTime, rolling: rolling) }

        let decay = CGFloat(exp(-Double(Tuning.cursorDamping * dt)))
        let dragBlend = min(1, dt * 10)

        // Solo i mucchi attivi raccolgono neve.
        var allPiles: [Pile] = settings.accumulate ? piles.values.map(\.pile) : []
        if settings.groundSnow, let dock { allPiles.append(dock.pile) }

        /// Muove un fiocco di un passo. Restituisce true se si è posato su un mucchio.
        func move(_ flake: inout Flake) -> Bool {
            var p = flake.node.position
            let previousY = p.y

            // --- Interazione col cursore ---
            let dx = p.x - mouse.x
            let dy = p.y - mouse.y
            let distance = hypot(dx, dy)
            if distance < cursorRadius, distance > 0.001 {
                let falloff = 1 - distance / cursorRadius
                let strength = falloff * falloff

                // 1) spinta radiale: i fiocchi si scostano dal puntatore
                let repel = cursorRepel * strength * dt
                flake.push.dx += dx / distance * repel
                flake.push.dy += dy / distance * repel

                // 2) trascinamento: se muovi il mouse velocemente li "spazzi" via
                let targetDX = mouseVelocity.dx * Tuning.cursorDrag
                let targetDY = mouseVelocity.dy * Tuning.cursorDrag
                flake.push.dx += (targetDX - flake.push.dx) * strength * dragBlend
                flake.push.dy += (targetDY - flake.push.dy) * strength * dragBlend
            }
            flake.push.dx *= decay
            flake.push.dy *= decay

            // --- Movimento naturale ---
            let sway = reduceMotion ? 0 : cos(elapsed * flake.swayFrequency * 2 * .pi + flake.phase)
                * flake.swayAmplitude * flake.swayFrequency
            // Vagare in su e in giù a un ritmo diverso dall'ondeggiare: il percorso non si ripete.
            let bob = reduceMotion || flake.bob == 0 ? 0 : sin(elapsed * flake.swayFrequency * 1.3 * .pi + flake.phase * 2)
                * flake.bob * flake.swayFrequency
            // Chi va di traverso ci va solo in vista: mentre aspetta sopra lo schermo (`gap`) scende dritto,
            // senza vento né drift, se no uscirebbe di lato prima di farsi vedere.
            let waiting = flake.drift != 0 && p.y > size.height + flake.extent
            if !waiting { p.x += (wind * (0.4 + flake.depth) + sway + flake.drift * fallSpeed + flake.push.dx) * dt }
            p.y += (-flake.fallSpeed * fallSpeed + bob + flake.push.dy) * dt

            if flake.drift != 0 {
                // Va di traverso: uscito di lato (in vista, non mentre aspetta sopra) è finito,
                // rinasce in cima (il chiamante lo vede sotto lo schermo).
                let out = flake.drift < 0 ? p.x < -flake.extent : p.x > size.width + flake.extent
                if out, p.y <= size.height + flake.extent { p.y = -flake.extent - 1 }
            } else {
                // Bordi laterali: chi esce da un lato rientra dall'altro.
                let margin = Tuning.sideMargin
                if p.x < -margin { p.x += size.width + margin * 2 }
                if p.x > size.width + margin { p.x -= size.width + margin * 2 }
            }

            flake.node.position = p
            if flake.spin != 0, !reduceMotion { flake.node.zRotation += flake.spin * dt }
            if flake.flip != 0, !reduceMotion { flake.node.xScale = cos(elapsed * flake.flip + flake.phase) }
            if flake.pulse != 0 {
                // Una lucciola: quasi spenta per un po', poi si accende piano.
                let glow = 0.5 + 0.5 * sin(elapsed * flake.pulse + flake.phase)
                flake.node.alpha = flake.alpha * (0.1 + 0.9 * glow * glow)
            }

            // --- Si posa? Ha attraversato la superficie di un mucchio in questo passo ---
            guard season.settles else { return false }
            for pile in allPiles {
                if let top = pile.surface(at: p.x), previousY >= top, p.y < top {
                    pile.add(atX: p.x, radius: flake.radius, growth: CGFloat(settings.growth) * .random(in: season.pileGrowth))
                    return true
                }
            }
            return false
        }

        for i in flakes.indices {
            var flake = flakes[i]
            // Posato o arrivato in fondo: rinasce in cima.
            if move(&flake) || flake.node.position.y < -flake.extent {
                respawn(&flake)
            }
            flakes[i] = flake
        }

        // --- Nebbia, nuvole, lampi e gocce sul vetro ---
        sky.step(dt: dt, width: size.width, calm: reduceMotion)
        glass.step(dt: dt, size: size, ledges: ledges, amount: intensity, calm: reduceMotion)
        nightClock += dt
        if nightClock >= 1 {
            nightClock = 0
            let hour = Calendar.current.component(.hour, from: .now)
            night.set(on: NightClock.isNight(mode: settings.night, startHour: settings.nightStart, hour: hour),
                      size: size, calm: reduceMotion)
        }
        night.step(dt: dt, calm: reduceMotion)

        // --- Oggetti: gravità, appoggio sui bordi scoperti, sul Dock o sul fondo dello schermo ---
        if !toys.isEmpty, !toysPaused {
            let toyLedges = ledges + [Ledge(y: 0, span: 0...size.width)]
            // I visitatori entrano e escono di lato: per loro il fondo continua fuori dallo schermo.
            let wideLedges = ledges + [Ledge(y: 0, span: -size.width...size.width * 2)]
            var broken: [Toy] = []
            for toy in toys {
                // Sulle finestre attaccate alla barra dei menu un oggetto alto la coprirebbe: lì non si ferma.
                let room = (ceiling ?? size.height) - toy.node.size.height
                let all = toy.staysOnScreen ? toyLedges : wideLedges
                let fit = all.contains { $0.y > room } ? all.filter { $0.y <= room } : all
                let falling = toy.body.velocity.dy
                let before = toy.body.velocity
                toy.body.step(dt: dt, ledges: fit, width: toy.staysOnScreen ? size.width : nil,
                              bounce: reduceMotion ? 0 : toy.bounce, friction: toy.friction)
                if toy.thrownHard {
                    // Lanciata forte: al primo urto (un bordo sotto, o il lato dello schermo) si rompe.
                    let landed = before.dy < 0 && toy.body.velocity.dy >= 0
                    let wall = before.dx != 0 && toy.body.velocity.dx * before.dx <= 0
                    if landed || wall {
                        broken.append(toy)
                        continue
                    }
                }
                // Una palla che arriva forte su un bordo fa "puf"; quelle che rotolano o rimbalzano piano no.
                if toy is Snowball, falling < -Tuning.toyMinBounce * 2, toy.body.velocity.dy >= 0 {
                    SoundBoard.shared.play("palla-di-neve-colpo")
                }
                toy.node.position = toy.body.position
                toy.step(dt: dt)
            }
            broken.forEach(shatter)
            stepLivelySnowmen()
            buildSnowman()
            stepWinterPlay()
            stepFigures(mouse: mouse)
            stepVisitors(dt: dt)
        } else if !toysPaused {
            stepVisitors(dt: dt)   // il trenino corre anche senza oggetti sulla scena
        }
        if !toysPaused { stepChristmas(dt: dt, mouse: mouse) }
        wantsMouse = wantsMouse(at: mouse)

        // --- Granelli di polvere: gravità + attrito dell'aria, niente oscillazione ---
        let drag = CGFloat(exp(-Double(Tuning.grainAirDrag * dt)))
        grains = grains.compactMap { grain in
            var grain = grain
            grain.velocity.dx *= drag
            grain.velocity.dy = grain.velocity.dy * drag - Tuning.grainGravity * dt
            var p = grain.node.position
            let previousY = p.y
            p.x += grain.velocity.dx * dt
            p.y += grain.velocity.dy * dt
            grain.node.position = p

            // Si posa su un mucchio più in basso (aggiunge poca neve: è un granello)…
            let landed = allPiles.first { pile in
                guard pile !== grain.source,
                      let top = pile.surface(at: p.x), previousY >= top, p.y < top else { return false }
                pile.add(atX: p.x, radius: 1, growth: CGFloat(settings.growth) * 0.3)
                return true
            }
            // …oppure esce dallo schermo: in entrambi i casi sparisce.
            if landed != nil || p.y < -5 || p.x < -20 || p.x > size.width + 20 {
                grain.node.removeFromParent()
                return nil
            }
            return grain
        }

        // --- Il cursore spazza la neve posata: si sbriciola in polvere che cade ---
        let speed = hypot(mouseVelocity.dx, mouseVelocity.dy)
        if speed > 20, CGRect(origin: .zero, size: size).contains(mouse) {
            // Spinta leggera nella direzione del cursore (limitata, se no i granelli volano via).
            if rolling {
                roll(at: mouse)
            } else {
                let drift = max(-150, min(150, mouseVelocity.dx * 0.15))
                for pile in allPiles {
                    spawnPowder(pile.scoop(at: mouse, radius: Tuning.scoopRadius), from: pile, drift: drift, spread: 25, pop: -10...40)
                }
            }
        }

        // La neve posata cambia lentamente: frana e ridisegno 10 volte al secondo bastano
        // (farlo a ogni frame triplicava la CPU).
        pileClock += dt
        if pileClock >= Tuning.pileSettleInterval {
            pileClock = 0
            let maxPile = CGFloat(settings.maxPile)
            for pile in piles.values.map(\.pile) + (dock.map { [$0.pile] } ?? []) {
                pile.maxHeight = pile === dock?.pile ? maxPile * Tuning.dockPileFactor : maxPile
                // Accumulo disattivato dalle impostazioni: la neve sparisce.
                if !allPiles.contains(where: { $0 === pile }) { pile.clear() }
                pile.settle()
                pile.redrawIfNeeded()
            }
        }
    }
}
