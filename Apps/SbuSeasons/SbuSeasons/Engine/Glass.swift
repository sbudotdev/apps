import AppKit
import SpriteKit

/// Una goccia sul vetro. Coordinate della scena.
nonisolated struct Drop: Equatable {
    let id: Int
    var position: CGPoint
    var radius: CGFloat
    /// Velocità verso il basso in pt/s: 0 = ferma.
    var speed: CGFloat = 0
    /// Arrivata su un bordo (finestra o Dock) è caduta giù: va libera, non si unisce più.
    var falling = false
}

/// Un tratto di vetro asciugato dal cursore (SBU-228): la pioggia non ci si posa, poi torna a coprirlo in `life` secondi.
nonisolated struct Wiped: Equatable {
    var center: CGPoint
    var radius: CGFloat
    /// Quando è stato asciugato l'ultima volta (orologio di `GlassDrops`).
    var born: CGFloat
    var life: CGFloat
    /// Gocce già tornate.
    var filled = 0
}

/// La pioggia sul vetro, senza disegno (lo fa `Glass`): le gocce si posano a caso; una goccia che ne tocca
/// un'altra la assorbe; quando è abbastanza pesante scorre giù, raccoglie quelle che incontra e lascia dietro
/// goccioline; arrivata sul bordo di una finestra o sul Dock cade, e sparisce sotto lo schermo.
nonisolated struct GlassDrops {
    let rain: GlassRain
    private(set) var drops: [Drop] = []
    /// Le gocce sparite nell'ultimo passo (unite a un'altra o uscite): chi le disegna toglie le loro sprite.
    private(set) var removed: [Int] = []
    /// Dove una goccia è arrivata su un bordo nell'ultimo passo: lì schizza (SBU-185).
    private(set) var splashes: [CGPoint] = []
    /// Le gocce asciugate dal cursore nell'ultimo passo: chi le disegna le fa sparire.
    private(set) var wiped: [Int] = []
    /// La scia del cursore che si sta richiudendo.
    private(set) var trail: [Wiped] = []
    private var nextID = 0
    private var due: CGFloat = 0
    private var clock: CGFloat = 0

    init(rain: GlassRain) { self.rain = rain }

    /// La goccia più grossa (oltre, una goccia unita non cresce più): un rigagnolo, non una pozza.
    var largest: CGFloat { rain.slide * 2.5 }

    /// Velocità a cui scorre una goccia di quel raggio: più pesante, più veloce.
    func runSpeed(_ radius: CGFloat, calm: Bool) -> CGFloat {
        let ratio = radius / rain.slide
        return min(260, 40 * ratio * ratio) * (calm ? 0.5 : 1)
    }

    /// Una goccia nuova in quel punto: se ne tocca un'altra, si uniscono.
    mutating func bead(at point: CGPoint, radius: CGFloat) {
        if let i = drops.firstIndex(where: { !$0.falling && touch($0, point, radius) }) {
            absorb(radius, into: i)
        } else {
            drops.append(Drop(id: nextID, position: point, radius: radius))
            nextID += 1
        }
    }

    /// Un passo. `amount`: intensità rispetto a "Media"; `ledges`: i bordi da cui una goccia cade; `calm`: Riduci movimento;
    /// `wipe`: il tratto fatto dal cursore in questo passo (da dov'era a dov'è), col suo raggio.
    mutating func step(dt: CGFloat, size: CGSize, ledges: [Ledge], amount: CGFloat, calm: Bool,
                       wipe: (from: CGPoint, to: CGPoint, radius: CGFloat)? = nil) {
        removed = []
        splashes = []
        wiped = []
        clock += dt
        guard size.width > 0, size.height > 0 else { return }
        if let wipe { self.wipe(from: wipe.from, to: wipe.to, radius: wipe.radius) }
        let area = size.width * size.height / Tuning.referenceScreenArea
        // Nuove gocce.
        due += rain.beads * amount * area * (calm ? 0.5 : 1) * dt
        let most = Int(CGFloat(rain.most) * area * max(amount, 0.3))
        while due >= 1 {
            due -= 1
            let radius = CGFloat.random(in: rain.size)
            if drops.count >= most, let i = drops.indices.randomElement() {
                // Vetro pieno: la pioggia cade sulle gocce che ci sono, che crescono e prima o poi scorrono.
                absorb(radius, into: i)
            } else {
                let point = CGPoint(x: .random(in: 0...size.width), y: .random(in: 0...size.height))
                // Sulla scia del cursore no: lì la pioggia torna da sola, a suo tempo.
                if !trail.contains(where: { hypot($0.center.x - point.x, $0.center.y - point.y) < $0.radius }) {
                    bead(at: point, radius: radius)
                }
            }
        }
        // Fitta come il vetro intorno.
        refill(density: CGFloat(drops.count) / (size.width * size.height), calm: calm)

        // Le gocce si muovono.
        var trail: [(CGPoint, CGFloat)] = []
        for i in drops.indices {
            var drop = drops[i]
            let previousY = drop.position.y
            if drop.falling {
                drop.speed += Tuning.grainGravity * 2 * dt
            } else if drop.radius >= rain.slide || drop.speed > 0 {
                // Accelera verso la sua velocità: una goccia grossa parte e scorre, una che si è assottigliata si ferma.
                let target = drop.radius >= rain.slide * 0.75 ? runSpeed(drop.radius, calm: calm) : 0
                drop.speed += (target - drop.speed) * min(1, dt * 4)
                if drop.speed < 2, target == 0 { drop.speed = 0 }
                if !calm { drop.position.x += sin(drop.position.y / 19 + CGFloat(drop.id)) * drop.speed * 0.15 * dt }
                // Lascia goccioline lungo la strada: perde un po' d'acqua.
                if drop.speed > 0, CGFloat.random(in: 0...1) < drop.speed * dt / 30 {
                    let crumb = drop.radius * 0.3
                    trail.append((drop.position, crumb))
                    drop.radius = sqrt(max(drop.radius * drop.radius - crumb * crumb, 0))
                }
            }
            drop.position.y -= drop.speed * dt
            // Scorrendo arriva su un bordo scoperto: lì non c'è più vetro libero, cade giù.
            if !drop.falling, drop.speed > 0,
               let ledge = ledges.first(where: { previousY >= $0.y && drop.position.y < $0.y && $0.span.contains(drop.position.x) }) {
                drop.falling = true
                splashes.append(CGPoint(x: drop.position.x, y: ledge.y))
            }
            drops[i] = drop
        }

        // Chi scorre assorbe le gocce che tocca.
        var gone = Set<Int>()
        for i in drops.indices where drops[i].speed > 0 && !drops[i].falling && !gone.contains(i) {
            for j in drops.indices where j != i && !gone.contains(j) && !drops[j].falling
                && touch(drops[i], drops[j].position, drops[j].radius) {
                absorb(drops[j].radius, into: i)
                gone.insert(j)
            }
        }
        // Unite a un'altra o fuori dallo schermo (in fondo o di lato): sparite.
        for (i, drop) in drops.enumerated()
        where gone.contains(i) || drop.position.y < -drop.radius * 4 || drop.position.x < -20 || drop.position.x > size.width + 20 {
            removed.append(drop.id)
        }
        if !removed.isEmpty {
            let ids = Set(removed)
            drops.removeAll { ids.contains($0.id) }
        }
        for (point, radius) in trail where radius >= 0.6 {
            drops.append(Drop(id: nextID, position: point, radius: radius))
            nextID += 1
        }
    }

    /// Asciuga tutto il tratto, un timbro ogni `Tuning.wipeStep` raggi: col cursore veloce la scia non resta a buchi
    /// (QA SBU-231).
    private mutating func wipe(from: CGPoint, to: CGPoint, radius: CGFloat) {
        guard radius > 0 else { return }
        let stamps = max(Int((hypot(to.x - from.x, to.y - from.y) / (radius * Tuning.wipeStep)).rounded(.up)), 1)
        for k in 1...stamps {
            let t = CGFloat(k) / CGFloat(stamps)
            wipe(at: CGPoint(x: from.x + (to.x - from.x) * t, y: from.y + (to.y - from.y) * t), radius: radius)
        }
    }

    /// Il cursore passa: le gocce ferme o che scorrono nel raggio spariscono (quelle che cadono vanno per la loro strada).
    private mutating func wipe(at point: CGPoint, radius: CGFloat) {
        drops.removeAll { drop in
            guard !drop.falling, hypot(drop.position.x - point.x, drop.position.y - point.y) < radius else { return false }
            wiped.append(drop.id)
            return true
        }
        // Ripassando su un tratto ancora fresco, si riasciuga; uno nuovo ogni `Tuning.wipeStep` raggi di strada.
        var near = false
        for i in trail.indices where hypot(trail[i].center.x - point.x, trail[i].center.y - point.y) < radius {
            trail[i].born = clock
            trail[i].filled = 0
            if hypot(trail[i].center.x - point.x, trail[i].center.y - point.y) < radius * Tuning.wipeStep { near = true }
        }
        if !near {
            trail.append(Wiped(center: point, radius: radius, born: clock, life: .random(in: RainTuning.wipeClose)))
        }
    }

    /// La pioggia ricopre la scia: a poco a poco fino a `life`; con Riduci movimento tutta insieme, alla fine.
    private mutating func refill(density: CGFloat, calm: Bool) {
        guard !trail.isEmpty else { return }
        let shares = trail.map { spot in
            let age = clock - spot.born
            return calm ? (age >= spot.life ? 1 : 0) : min(1, age / spot.life)
        }
        for i in trail.indices {
            let spot = trail[i]
            let target = Int(density * .pi * spot.radius * spot.radius * shares[i])
            for _ in spot.filled..<max(spot.filled, target) {
                let angle = CGFloat.random(in: 0..<2 * .pi), r = spot.radius * sqrt(.random(in: 0...1))
                let point = CGPoint(x: spot.center.x + cos(angle) * r, y: spot.center.y + sin(angle) * r)
                // Dove i tratti si sovrappongono riempie solo il meno avanti: se no lì l'acqua si somma.
                let behind = trail.indices.contains { j in
                    j != i && shares[j] < shares[i]
                        && hypot(trail[j].center.x - point.x, trail[j].center.y - point.y) < trail[j].radius
                }
                if !behind { bead(at: point, radius: .random(in: rain.size)) }
            }
            trail[i].filled = max(spot.filled, target)
        }
        trail.removeAll { clock - $0.born >= $0.life }
    }

    private func touch(_ drop: Drop, _ point: CGPoint, _ radius: CGFloat) -> Bool {
        hypot(drop.position.x - point.x, drop.position.y - point.y) < drop.radius + radius
    }

    /// Acqua che si aggiunge a una goccia: le aree si sommano.
    private mutating func absorb(_ radius: CGFloat, into i: Int) {
        drops[i].radius = min(hypot(drops[i].radius, radius), largest)
    }
}

/// Disegna `GlassDrops`: una sprite per goccia, allungata quando scorre o cade.
final class Glass: SKNode {
    private(set) var model: GlassDrops?
    private var nodes: [Int: SKSpriteNode] = [:]
    private var texture: SKTexture?

    /// Cambia pioggia (nil = niente gocce): quelle di prima spariscono.
    func set(_ rain: GlassRain?) {
        removeAllChildren()
        nodes = [:]
        model = rain.map(GlassDrops.init)
        texture = rain.map { Self.makeTexture($0.color) }
    }

    /// Dove le gocce sono arrivate su un bordo nell'ultimo passo.
    var splashes: [CGPoint] { model?.splashes ?? [] }

    func step(dt: CGFloat, size: CGSize, ledges: [Ledge], amount: CGFloat, calm: Bool,
              wipe: (from: CGPoint, to: CGPoint, radius: CGFloat)? = nil) {
        guard var model, let texture else { return }
        model.step(dt: dt, size: size, ledges: ledges, amount: amount, calm: calm, wipe: wipe)
        self.model = model
        for id in model.removed {
            nodes.removeValue(forKey: id)?.removeFromParent()
        }
        for id in model.wiped {
            guard let node = nodes.removeValue(forKey: id) else { continue }
            if calm { node.removeFromParent() } else { node.run(.sequence([.fadeOut(withDuration: RainTuning.wipeFade), .removeFromParent()])) }
        }
        for drop in model.drops {
            let node = nodes[drop.id] ?? {
                let node = SKSpriteNode(texture: texture)
                node.zPosition = 1.7   // davanti alle particelle, dietro ai mucchi e agli oggetti
                addChild(node)
                nodes[drop.id] = node
                return node
            }()
            node.position = drop.position
            let stretch = 1 + min(drop.speed / (drop.falling ? 300 : 150), drop.falling ? 1.5 : 0.6)
            node.size = CGSize(width: drop.radius * 2, height: drop.radius * 2 * stretch)
        }
    }

    /// Una goccia d'acqua vista contro luce: quasi trasparente, il bordo in basso più scuro, un riflesso in alto a sinistra.
    private static func makeTexture(_ color: NSColor) -> SKTexture {
        let side: CGFloat = 32
        let image = NSImage(size: NSSize(width: side, height: side), flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            let body = rect.insetBy(dx: 1, dy: 1)
            ctx.setFillColor(color.withAlphaComponent(0.18).cgColor)
            ctx.fillEllipse(in: body)
            ctx.setStrokeColor(color.blended(withFraction: 0.5, of: .black)?.withAlphaComponent(0.45).cgColor ?? color.cgColor)
            ctx.setLineWidth(2)
            ctx.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: body.width / 2 - 1,
                       startAngle: .pi * 1.1, endAngle: .pi * 1.9, clockwise: false)
            ctx.strokePath()
            ctx.setFillColor(NSColor.white.withAlphaComponent(0.85).cgColor)
            ctx.fillEllipse(in: CGRect(x: side * 0.28, y: side * 0.58, width: side * 0.22, height: side * 0.16))
            return true
        }
        return SKTexture(image: image)
    }
}
