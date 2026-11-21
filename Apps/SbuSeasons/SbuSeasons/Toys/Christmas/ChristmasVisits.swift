import AppKit
import SpriteKit

/// Natale sulla scena: Babbo Natale attraversa lo schermo quando lo manda `Passages` (da solo o dal menu),
/// lascia un regalo al giorno; l'omino di pan di zenzero corre sul Dock. Solo d'inverno: cambiando stagione spariscono.
extension SeasonScene {

    // MARK: - Babbo Natale

    /// Babbo Natale attraversa questo schermo, verso `heading` (1 = destra) alla quota `altitude` (nil = la solita).
    /// `carriesGift` nil: lo decide qui, come una visita chiesta dal menu (`manual`) o programmata. Il resto (quando, su quali
    /// schermi, il suono) lo decide `Passages`. nil = non è inverno, i giochi sono in pausa o sta già volando.
    @discardableResult
    func sendSanta(manual: Bool = true, heading: CGFloat = Bool.random() ? 1 : -1, altitude: CGFloat? = nil,
                   carriesGift: Bool? = nil) -> Santa? {
        guard season is Snow, santa == nil, !toysPaused else { return nil }
        let carries = carriesGift ?? {
            let canGive = christmas.diary.canGive(on: christmas.now())
            return manual ? canGive : SantaVisits.carriesGift(eve: christmas.isEve, canGive: canGive, roll: .random(in: 0..<1))
        }()
        let santa = Santa(heading: heading, carriesGift: carries)
        santa.altitude = altitude ?? (ceiling ?? size.height) * Tuning.santaAltitude
        santa.dropX = carries ? giftTarget() : nil
        santaVisits += 1
        // Con Riduci movimento la slitta non attraversa lo schermo: il regalo cade dritto dove sarebbe arrivato.
        if reduceMotion {
            if let x = santa.dropX { dropGift(at: CGPoint(x: x, y: santa.altitude)) }
            return santa
        }
        let half = santa.node.size.width / 2
        santa.node.position = CGPoint(x: santa.heading > 0 ? -half : size.width + half, y: santa.altitude)
        addChild(santa.node)
        self.santa = santa
        return santa
    }

    /// Un punto a caso sul bordo di una finestra o sul Dock; senza, sul fondo.
    private func giftTarget() -> CGFloat {
        let margin: CGFloat = 12
        guard let ledge = ledges.filter({ $0.span.upperBound - $0.span.lowerBound > margin * 2 }).randomElement()
        else { return .random(in: size.width * 0.15...size.width * 0.85) }
        return .random(in: ledge.span.lowerBound + margin...ledge.span.upperBound - margin)
    }

    /// Il diario si ricontrolla qui, non solo alla partenza: con due schermi due slitte possono volare insieme.
    private func dropGift(at point: CGPoint) {
        guard christmas.diary.canGive(on: christmas.now()) else { return }
        add(Gift(at: point))
        christmas.diary.recordGift(on: christmas.now())
    }

    // MARK: - Regalo e omino

    /// Il regalo appena aperto: stelline, e ne salta fuori un omino di pan di zenzero.
    func unwrap(_ gift: Gift) {
        let feet = gift.body.position
        sparkle(at: CGPoint(x: feet.x, y: feet.y + 14))
        let man = addGingerbreadMan(at: CGPoint(x: feet.x, y: feet.y + 4))
        if !reduceMotion { man.body.velocity = CGVector(dx: man.heading * 120, dy: Tuning.gingerbreadJump) }
    }

    /// "Manda l'omino di pan di zenzero": parte dal bordo sinistro del Dock (senza Dock, dal fondo).
    @discardableResult
    func sendGingerbreadMan() -> GingerbreadMan? {
        guard season is Snow else { return nil }
        let start = dockLedge.map { CGPoint(x: $0.span.lowerBound + 12, y: $0.y) } ?? CGPoint(x: 12, y: 0)
        SoundBoard.shared.play("omino")
        return addGingerbreadMan(at: start)
    }

    private func addGingerbreadMan(at point: CGPoint) -> GingerbreadMan {
        let man = GingerbreadMan(at: point)
        man.heading = point.x < size.width / 2 ? 1 : -1
        add(man)
        let men = toys.compactMap { $0 as? GingerbreadMan }
        men.prefix(max(0, men.count - Tuning.maxGingerbreadMen)).forEach(remove)
        return man
    }

    /// Qualche stellina che si allarga e svanisce (con Riduci movimento svanisce e basta).
    func sparkle(at point: CGPoint) {
        for i in 0..<8 {
            let star = SKSpriteNode(texture: Self.starTexture)
            star.size = CGSize(width: 7, height: 7)
            star.position = point
            star.zPosition = 3
            addChild(star)
            let angle = CGFloat(i) * .pi / 4
            let spread = reduceMotion ? SKAction.wait(forDuration: 0.6)
                : .move(by: CGVector(dx: cos(angle) * 22, dy: sin(angle) * 22), duration: 0.6)
            star.run(.sequence([.group([spread, .fadeOut(withDuration: 0.6)]), .removeFromParent()]))
        }
    }

    private static let starTexture = drawnTexture(size: CGSize(width: 7, height: 7)) { rect in
        let star = NSBezierPath()
        for i in 0..<10 {
            let angle = CGFloat(i) * .pi / 5 + .pi / 2
            let r: CGFloat = i % 2 == 0 ? 3.5 : 1.4
            let p = CGPoint(x: rect.midX + cos(angle) * r, y: rect.midY + sin(angle) * r)
            if i == 0 { star.move(to: p) } else { star.line(to: p) }
        }
        star.close()
        NSColor.systemYellow.setFill()
        star.fill()
    }

    // MARK: - Passo

    /// A ogni passo (se i giochi non sono in pausa): Babbo Natale vola, i regali aperti
    /// che spariscono, l'omino che corre e scappa dal cursore (`mouse`, coordinate della scena).
    func stepChristmas(dt: CGFloat, mouse: CGPoint) {
        guard season is Snow else { return }
        if let santa {
            var p = santa.node.position
            p.x += santa.heading * Tuning.santaSpeed * dt
            p.y = santa.altitude + (reduceMotion ? 0 : sin(elapsed * 2.2) * 5)
            santa.node.position = p
            if let x = santa.dropX, santa.heading > 0 ? p.x >= x : p.x <= x {
                santa.dropX = nil
                dropGift(at: CGPoint(x: x, y: p.y - 8))
            }
            if p.x < -santa.node.size.width || p.x > size.width + santa.node.size.width {
                santa.node.removeFromParent()
                self.santa = nil
                onSantaLeft?(santa.altitude)
            }
        }

        stepLetter()
        for gift in toys.compactMap({ $0 as? Gift }) where gift.openFor >= Tuning.giftLinger { remove(gift) }

        let floor = Ledge(y: 0, span: 0...size.width)
        for man in toys.compactMap({ $0 as? GingerbreadMan }) where man.body.isResting {
            let feet = man.body.position
            let ledge = ledges.first { abs($0.y - feet.y) < 0.5 && $0.span.contains(feet.x) } ?? floor
            let run = GingerbreadMan.run(x: feet.x, span: ledge.span, heading: man.heading, mouse: mouse, feetY: feet.y)
            man.heading = run.heading
            let speed = reduceMotion ? Tuning.gingerbreadWalk / 2 : run.fleeing ? Tuning.gingerbreadDash : Tuning.gingerbreadWalk
            man.body.velocity.dx = run.heading * speed
            if run.jumps, !reduceMotion { man.body.velocity.dy = Tuning.gingerbreadJump }
        }
    }

    /// Cambiando stagione: via la slitta in volo, i regali e gli omini.
    func removeChristmas() {
        santa?.node.removeFromParent()
        santa = nil
        letter?.removeFromParent()
        letter = nil
        toys.filter { $0 is Gift || $0 is GingerbreadMan }.forEach(remove)
    }
}
