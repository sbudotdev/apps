import AppKit
import SpriteKit

/// La scena SpriteKit che disegna e muove i fiocchi.
///
/// Coordinate: origine in basso a sinistra (come SpriteKit e come `NSEvent.mouseLocation`),
/// un punto della scena = un punto dello schermo.
final class SnowScene: SKScene {

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
        let source: SnowPile?
    }
    private var grains: [Grain] = []

    /// Neve posata sulle finestre, per ID di finestra. `rect` è in coordinate della scena.
    private var piles: [CGWindowID: (pile: SnowPile, rect: CGRect)] = [:]
    /// Neve posata sopra il Dock. `rect` è in coordinate della scena.
    private var dock: (pile: SnowPile, rect: CGRect)?
    private let flakeTexture = SnowScene.makeFlakeTexture()
    private let screenOrigin: CGPoint

    private var lastUpdateTime: TimeInterval?
    private var elapsed: CGFloat = 0
    private var lastMouse: CGPoint?
    /// Tempo dall'ultimo aggiornamento dei mucchi (frana + ridisegno).
    private var pileClock: CGFloat = 0

    /// Quantità e dimensione con cui sono stati creati i fiocchi attuali:
    /// se nelle impostazioni cambiano, li ricreiamo.
    private var builtWith: (count: Double, size: Double)?

    // MARK: - Init

    init(size: CGSize, screenOrigin: CGPoint) {
        self.screenOrigin = screenOrigin
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

    // MARK: - Fiocchi

    private func rebuildFlakes() {
        flakes.forEach { $0.node.removeFromParent() }
        guard size.width > 0, size.height > 0 else {
            flakes = []
            return
        }
        let settings = Settings.shared.values
        builtWith = (settings.flakeCount, settings.flakeSize)
        let count = Int(settings.flakeCount * Double(size.width * size.height / Tuning.referenceScreenArea))
        flakes = (0..<max(count, 1)).map { _ in
            makeFlake(at: CGPoint(x: .random(in: 0...size.width), y: .random(in: 0...size.height)))
        }
    }

    /// Crea un fiocco nel punto indicato.
    private func makeFlake(at position: CGPoint) -> Flake {
        let depth = CGFloat.random(in: 0...1)
        let radius = (1.5 + depth * 3.5) * Settings.shared.values.flakeSize

        let node = SKSpriteNode(texture: flakeTexture)
        node.size = CGSize(width: radius * 2, height: radius * 2)
        node.alpha = 0.45 + depth * 0.5
        node.zPosition = depth
        node.position = position
        addChild(node)

        return Flake(
            node: node,
            radius: radius,
            depth: depth,
            fallSpeed: 22 + depth * 58,
            swayAmplitude: .random(in: 8...26),
            swayFrequency: .random(in: 0.3...0.9),
            phase: .random(in: 0...(2 * .pi))
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
    private func spawnPowder(_ points: [CGPoint], from source: SnowPile? = nil, drift: CGFloat = 0,
                             spread: CGFloat = 8, pop: ClosedRange<CGFloat> = -5...5) {
        for point in points where grains.count < Tuning.maxGrains {
            let node = SKSpriteNode(texture: flakeTexture)
            let diameter = CGFloat.random(in: 2...4)   // più piccoli dei fiocchi: è polvere
            node.size = CGSize(width: diameter, height: diameter)
            node.alpha = .random(in: 0.8...1)
            node.zPosition = 1.5
            node.position = point
            addChild(node)
            grains.append(Grain(node: node, velocity: CGVector(dx: drift + .random(in: -spread...spread),
                                                               dy: .random(in: pop)), source: source))
        }
    }

    // MARK: - Finestre

    /// Riceve finestre e Dock attuali (coordinate globali) e aggiorna i mucchi di neve.
    /// `ceiling`: dove finisce la zona libera dello schermo, sotto la barra dei menu (coordinate della scena).
    func updateWindows(_ edges: [WindowEdge], dock dockFrame: CGRect?, ceiling: CGFloat) {
        updateDock(dockFrame)
        let maxPile = CGFloat(Settings.shared.values.maxPile)
        var seen = Set<CGWindowID>()
        for edge in edges {
            let r = edge.rect.offsetBy(dx: -screenOrigin.x, dy: -screenOrigin.y)
            // Solo bordi su questo schermo, con il mucchio sotto la barra dei menu (decisione di Matteo, MGS-416).
            guard r.maxY > 0, r.maxX > 0, r.minX < size.width,
                  collectsSnow(edgeTop: r.maxY, pileHeight: maxPile, ceiling: ceiling) else { continue }
            seen.insert(edge.id)
            let open = edge.visible.map { ($0.lowerBound - screenOrigin.x)...($0.upperBound - screenOrigin.x) }

            if let old = piles[edge.id], old.rect.minX == r.minX, old.rect.maxY == r.maxY, old.rect.width == r.width,
               old.pile.cornerRadius == edge.cornerRadius {
                // Ferma: aggiorna solo i tratti coperti/scoperti.
                spawnPowder(old.pile.setOpen(open), from: old.pile)
            } else {
                // Nuova, spostata, ridimensionata (o scoperto il raggio giusto): la neve vecchia cade, si riparte da zero.
                if let old = piles[edge.id] { drop(old.pile) }
                let pile = SnowPile(minX: r.minX, width: r.width, baseY: r.maxY, cornerRadius: edge.cornerRadius,
                                    maxHeight: maxPile)
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
        let pile = SnowPile(minX: r.minX, width: r.width, baseY: r.maxY, cornerRadius: Tuning.dockCornerRadius,
                            maxHeight: CGFloat(Settings.shared.values.maxPile) * Tuning.dockPileFactor)
        addChild(pile.node)
        dock = (pile, r)
    }

    private func drop(_ pile: SnowPile) {
        spawnPowder(pile.releaseAll())
        pile.node.removeFromParent()
    }

    /// "Sciogli la neve": svuota tutti i mucchi.
    func meltAll() {
        piles.values.forEach { $0.pile.clear() }
        dock?.pile.clear()
    }

    // MARK: - Loop

    override func update(_ currentTime: TimeInterval) {
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
        let maxWind = CGFloat(settings.wind)
        let wind = sin(elapsed * 0.11) * maxWind + sin(elapsed * 0.37) * maxWind * 0.3

        // Posizione e velocità del cursore in coordinate della scena.
        let global = NSEvent.mouseLocation
        let mouse = CGPoint(x: global.x - screenOrigin.x, y: global.y - screenOrigin.y)
        var mouseVelocity = CGVector.zero
        if let last = lastMouse {
            mouseVelocity = CGVector(dx: (mouse.x - last.x) / dt, dy: (mouse.y - last.y) / dt)
        }
        lastMouse = mouse

        let decay = CGFloat(exp(-Double(Tuning.cursorDamping * dt)))
        let dragBlend = min(1, dt * 10)

        // Solo i mucchi attivi raccolgono neve.
        var allPiles: [SnowPile] = settings.accumulate ? piles.values.map(\.pile) : []
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
            let sway = cos(elapsed * flake.swayFrequency * 2 * .pi + flake.phase)
                * flake.swayAmplitude * flake.swayFrequency
            p.x += (wind * (0.4 + flake.depth) + sway + flake.push.dx) * dt
            p.y += (-flake.fallSpeed * fallSpeed + flake.push.dy) * dt

            // Bordi laterali: chi esce da un lato rientra dall'altro.
            let margin = Tuning.sideMargin
            if p.x < -margin { p.x += size.width + margin * 2 }
            if p.x > size.width + margin { p.x -= size.width + margin * 2 }

            flake.node.position = p

            // --- Si posa? Ha attraversato la superficie di un mucchio in questo passo ---
            for pile in allPiles {
                if let top = pile.surface(at: p.x), previousY >= top, p.y < top {
                    pile.add(atX: p.x, radius: flake.radius, growth: CGFloat(settings.growth))
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

    // MARK: - Texture

    /// Un pallino bianco sfumato con un leggerissimo bordo grigio-azzurro,
    /// così la neve resta visibile anche sopra le finestre bianche.
    private static func makeFlakeTexture(diameter: CGFloat = 32) -> SKTexture {
        let size = NSSize(width: diameter, height: diameter)
        let image = NSImage(size: size, flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            let colors = [
                NSColor(white: 1, alpha: 1).cgColor,
                NSColor(white: 1, alpha: 0.9).cgColor,
                NSColor(calibratedRed: 0.72, green: 0.80, blue: 0.90, alpha: 0.45).cgColor,
                NSColor(calibratedRed: 0.72, green: 0.80, blue: 0.90, alpha: 0).cgColor,
            ] as CFArray
            let locations: [CGFloat] = [0, 0.45, 0.75, 1]
            guard let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors,
                locations: locations
            ) else { return false }
            let center = CGPoint(x: rect.midX, y: rect.midY)
            ctx.drawRadialGradient(
                gradient,
                startCenter: center, startRadius: 0,
                endCenter: center, endRadius: rect.width / 2,
                options: []
            )
            return true
        }
        return SKTexture(image: image)
    }
}
