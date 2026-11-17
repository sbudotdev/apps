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
    private var ledges: [Ledge] = []
    /// L'oggetto in mano al cursore: dove l'ha preso, dov'è partito, l'ultima posizione e la velocità del lancio.
    private var held: (toy: Toy, grip: CGVector, start: CGPoint, last: CGPoint, time: TimeInterval, velocity: CGVector)?
    private var pointerShake = ShakeDetector()

    /// "Riduci movimento" di macOS: metà dei fiocchi, niente vento, oscillazione, rotazione, lanci o rimbalzi.
    var reduceMotion = false {
        didSet { if reduceMotion != oldValue, !flakes.isEmpty { rebuildFlakes() } }
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
        for pile in piles.values.map(\.pile) + (dock.map { [$0.pile] } ?? []) { pile.node.fillColor = season.pileColor }
        rebuildFlakes()
    }

    // MARK: - Fiocchi

    private func rebuildFlakes() {
        flakes.forEach { $0.node.removeFromParent() }
        guard size.width > 0, size.height > 0 else {
            flakes = []
            return
        }
        let settings = Settings.shared.values
        builtWith = (settings.flakeCount, settings.flakeSize)
        let calm = reduceMotion ? Tuning.reducedMotionFlakes : 1
        let count = Int(settings.flakeCount * Double(size.width * size.height / Tuning.referenceScreenArea * calm))
        flakes = (0..<max(count, 1)).map { _ in
            makeFlake(at: CGPoint(x: .random(in: 0...size.width), y: .random(in: 0...size.height)))
        }
    }

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
            flip: particle.flip * 2 * .pi
        )
    }

    private func respawn(_ flake: inout Flake) {
        flake.node.position = CGPoint(
            x: .random(in: 0...size.width),
            y: size.height + flake.radius + .random(in: 0...40)
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
        held != nil || toy(at: point) != nil
    }
    /// `wantsMouse` nel punto del cursore, ricalcolato a ogni passo.
    private(set) var wantsMouse = false

    /// Pressione del mouse: prende l'oggetto sotto il punto. false = non c'è niente.
    @discardableResult
    func grab(at point: CGPoint, time: TimeInterval) -> Bool {
        guard let toy = toy(at: point) else { return false }
        let feet = toy.body.position
        held = (toy, CGVector(dx: point.x - feet.x, dy: point.y - feet.y), point, point, time, .zero)
        toy.body.hold(at: feet)
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
        held.toy.body.hold(at: CGPoint(x: point.x - held.grip.dx, y: point.y - held.grip.dy))
        held.toy.node.position = held.toy.body.position
        self.held = held
    }

    /// Rilascio: un clic se il mouse non si è quasi mosso, se no un lancio (con Riduci movimento cade dritto).
    func letGo(at point: CGPoint, time: TimeInterval) {
        drag(to: point, time: time)
        guard let held else { return }
        self.held = nil
        let isClick = hypot(point.x - held.start.x, point.y - held.start.y) < Tuning.clickSlop
        // Fermo da un po' prima di lasciarlo: nessun lancio.
        let stale = time - held.time > 0.1
        held.toy.body.release(velocity: isClick || stale || reduceMotion ? .zero : held.velocity)
        if isClick { held.toy.clicked() }
    }

    /// Il cursore si è mosso su questo schermo: se è stato scosso, lo sanno tutti gli oggetti.
    func pointerMoved(to point: CGPoint, time: TimeInterval) {
        if pointerShake.add(point, at: time) { toys.forEach { $0.shaken(.pointer) } }
    }

    /// Finestre scosse (le riconosce `AppDelegate`, una volta per tutti gli schermi).
    func windowsShaken(_ ids: Set<CGWindowID>) {
        for id in ids { toys.forEach { $0.shaken(.window(id)) } }
    }

    override func mouseDown(with event: NSEvent) { grab(at: event.location(in: self), time: event.timestamp) }
    override func mouseDragged(with event: NSEvent) { drag(to: event.location(in: self), time: event.timestamp) }
    override func mouseUp(with event: NSEvent) { letGo(at: event.location(in: self), time: event.timestamp) }

    // MARK: - Finestre

    /// Riceve finestre e Dock attuali (coordinate globali) e aggiorna i mucchi di neve.
    /// `ceiling`: dove finisce la zona libera dello schermo, sotto la barra dei menu (coordinate della scena).
    func updateWindows(_ edges: [WindowEdge], dock dockFrame: CGRect?, ceiling: CGFloat) {
        updateDock(dockFrame)
        let maxPile = CGFloat(Settings.shared.values.maxPile)
        var seen = Set<CGWindowID>()
        ledges = dock.map { [Ledge(y: $0.rect.maxY, span: $0.rect.minX...$0.rect.maxX)] } ?? []
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
                // Nuova, spostata, ridimensionata (o scoperto il raggio giusto): la neve vecchia cade, si riparte da zero.
                if let old = piles[edge.id] { drop(old.pile) }
                let pile = Pile(minX: r.minX, width: r.width, baseY: base, cornerRadius: edge.cornerRadius,
                                maxHeight: maxPile, color: season.pileColor)
                _ = pile.setOpen(open)
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

    private func drop(_ pile: Pile) {
        spawnPowder(pile.releaseAll())
        pile.node.removeFromParent()
    }

    /// "Sciogli la neve": svuota tutti i mucchi.
    func meltAll() {
        piles.values.forEach { $0.pile.clear() }
        dock?.pile.clear()
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
            rebuildFlakes()
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
        if CGRect(origin: .zero, size: size).contains(mouse) { pointerMoved(to: mouse, time: currentTime) }

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
            p.x += (wind * (0.4 + flake.depth) + sway + flake.push.dx) * dt
            p.y += (-flake.fallSpeed * fallSpeed + flake.push.dy) * dt

            // Bordi laterali: chi esce da un lato rientra dall'altro.
            let margin = Tuning.sideMargin
            if p.x < -margin { p.x += size.width + margin * 2 }
            if p.x > size.width + margin { p.x -= size.width + margin * 2 }

            flake.node.position = p
            if flake.spin != 0, !reduceMotion { flake.node.zRotation += flake.spin * dt }
            if flake.flip != 0, !reduceMotion { flake.node.xScale = cos(elapsed * flake.flip + flake.phase) }

            // --- Si posa? Ha attraversato la superficie di un mucchio in questo passo ---
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
            if move(&flake) || flake.node.position.y < -flake.radius {
                respawn(&flake)
            }
            flakes[i] = flake
        }

        // --- Oggetti: gravità, appoggio sui bordi scoperti, sul Dock o sul fondo dello schermo ---
        if !toys.isEmpty {
            let toyLedges = ledges + [Ledge(y: 0, span: 0...size.width)]
            for toy in toys {
                toy.body.step(dt: dt, ledges: toyLedges, width: size.width, bounce: reduceMotion ? 0 : toy.bounce)
                toy.node.position = toy.body.position
            }
        }
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
            let drift = max(-150, min(150, mouseVelocity.dx * 0.15))
            for pile in allPiles {
                spawnPowder(pile.scoop(at: mouse, radius: Tuning.scoopRadius), from: pile, drift: drift, spread: 25, pop: -10...40)
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
