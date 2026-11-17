import AppKit
import SpriteKit

/// I personaggi del menu, uno per tipo: stanno sui bordi delle finestre, sul Dock o sul fondo e reagiscono al clic.
nonisolated enum FigureKind: CaseIterable, Sendable {
    case fox, tit, cabin, lantern, reindeer

    var title: String {
        switch self {
        case .fox: String(localized: "Volpe")
        case .tit: String(localized: "Cincia e mangiatoia")
        case .cabin: String(localized: "Baita")
        case .lantern: String(localized: "Lanterna")
        case .reindeer: String(localized: "Renna")
        }
    }

    var tip: String {
        switch self {
        case .fox: String(localized: "Dorme acciambellata: fai clic per svegliarla. Annusa, fa due passi e torna a dormire.")
        case .tit: String(localized: "Fai clic sulla mangiatoia per mettere i semi: arriva la cincia a beccarli.")
        case .cabin: String(localized: "Fai clic per accendere il fuoco: la finestra si scalda e dal camino esce il fumo.")
        case .lantern: String(localized: "Fai clic per accenderla o spegnerla.")
        case .reindeer: String(localized: "Cammina sopra le finestre. Avvicina il cursore: il naso si illumina.")
        }
    }
}

/// Un personaggio: un oggetto come gli altri (si trascina, cade, sta sui bordi) che sa di che tipo è.
class Figure: Toy {
    let kind: FigureKind

    init(kind: FigureKind, texture: SKTexture, at position: CGPoint) {
        self.kind = kind
        let node = SKSpriteNode(texture: texture)
        node.size = texture.size()
        super.init(node: node, at: position)
    }

    var calm: Bool { (node.scene as? SeasonScene)?.reduceMotion ?? false }

    /// Chi cammina: 1 = verso destra, -1 = verso sinistra.
    var heading: CGFloat = 1
    /// A che velocità cammina adesso sul suo bordo (pt/s). nil = sta ferma (la muove solo il motore).
    var walkSpeed: CGFloat? { nil }
}

/// Chi cammina avanti e indietro sul suo bordo: si gira `margin` pt prima della fine, così non cade.
nonisolated enum Pacing {
    static func heading(x: CGFloat, span: ClosedRange<CGFloat>, heading: CGFloat, margin: CGFloat) -> CGFloat {
        span.contains(x + heading * margin) ? heading : -heading
    }
}

private let warmLight = NSColor(calibratedRed: 1, green: 0.72, blue: 0.35, alpha: 1)

// MARK: - Volpe

/// La volpe: dorme acciambellata; un clic la sveglia, annusa un po', cammina sul suo bordo e torna a dormire.
final class Fox: Figure {
    nonisolated enum Mood: Equatable { case asleep, sniffing, walking }

    /// Da quanto è sveglia (s). nil = dorme.
    private var awakeFor: CGFloat?
    var mood: Mood { Self.mood(awakeFor: awakeFor) }
    override var walkSpeed: CGFloat? { mood == .walking ? Tuning.foxWalk : nil }

    init(at position: CGPoint) {
        super.init(kind: .fox, texture: Self.asleep, at: position)
    }

    nonisolated static func mood(awakeFor: CGFloat?) -> Mood {
        guard let awakeFor, awakeFor < Tuning.foxAwake else { return .asleep }
        return awakeFor < Tuning.foxSniff ? .sniffing : .walking
    }

    override func clicked() {
        guard mood == .asleep else { return }
        awakeFor = 0
        node.texture = Self.awake
        node.size = Self.awake.size()
        SoundBoard.shared.play("volpe")
    }

    override func step(dt: CGFloat) {
        guard let awake = awakeFor else { return }
        awakeFor = awake + dt
        if mood == .asleep {
            awakeFor = nil
            node.texture = Self.asleep
            node.size = Self.asleep.size()
            node.zRotation = 0
        }
        node.xScale = heading
        // Annusa: il muso va su e giù (con Riduci movimento sta ferma).
        node.zRotation = mood == .sniffing && !calm ? sin(awake * 9) * 0.05 : 0
    }

    private static let orange = NSColor(calibratedRed: 0.86, green: 0.45, blue: 0.16, alpha: 1)
    private static let cream = NSColor(calibratedRed: 0.98, green: 0.93, blue: 0.85, alpha: 1)
    private static let dark = NSColor(calibratedRed: 0.22, green: 0.14, blue: 0.1, alpha: 1)

    /// Acciambellata: il corpo tondo, la coda bianca in punta che la avvolge, le orecchie e l'occhio chiuso.
    private static let asleep = drawnTexture(size: CGSize(width: 34, height: 16)) { _ in
        orange.setFill()
        NSBezierPath(ovalIn: CGRect(x: 2, y: 0, width: 28, height: 14)).fill()
        let ear = NSBezierPath()
        ear.move(to: CGPoint(x: 22, y: 11)); ear.line(to: CGPoint(x: 25, y: 16)); ear.line(to: CGPoint(x: 27, y: 10)); ear.close()
        ear.fill()
        // La coda che gira davanti, con la punta bianca.
        NSBezierPath(ovalIn: CGRect(x: 6, y: 0, width: 26, height: 7)).fill()
        cream.setFill()
        NSBezierPath(ovalIn: CGRect(x: 26, y: 0.5, width: 7, height: 6)).fill()
        dark.setStroke()
        let eye = NSBezierPath()
        eye.move(to: CGPoint(x: 23, y: 9)); eye.line(to: CGPoint(x: 26, y: 8.5))
        eye.lineWidth = 0.8
        eye.stroke()
    }

    /// In piedi, guarda a destra: zampe scure, coda folta all'indietro, muso a punta.
    private static let awake = drawnTexture(size: CGSize(width: 38, height: 22)) { _ in
        dark.setFill()
        for x in [9.0, 13, 22, 26] { NSBezierPath(rect: CGRect(x: x, y: 0, width: 2.2, height: 7)).fill() }
        orange.setFill()
        NSBezierPath(ovalIn: CGRect(x: 7, y: 5, width: 23, height: 10)).fill()          // corpo
        let tail = NSBezierPath(ovalIn: CGRect(x: 0, y: 7, width: 13, height: 6))
        tail.fill()
        cream.setFill()
        NSBezierPath(ovalIn: CGRect(x: 0, y: 7.5, width: 4.5, height: 5)).fill()        // punta della coda
        orange.setFill()
        NSBezierPath(ovalIn: CGRect(x: 26, y: 11, width: 9, height: 8)).fill()          // testa
        let snout = NSBezierPath()
        snout.move(to: CGPoint(x: 33, y: 16)); snout.line(to: CGPoint(x: 38, y: 13.5)); snout.line(to: CGPoint(x: 32, y: 12)); snout.close()
        snout.fill()
        for x in [27.0, 31] {
            let ear = NSBezierPath()
            ear.move(to: CGPoint(x: x, y: 17)); ear.line(to: CGPoint(x: x + 1.5, y: 22)); ear.line(to: CGPoint(x: x + 3.5, y: 17)); ear.close()
            ear.fill()
        }
        cream.setFill()
        NSBezierPath(ovalIn: CGRect(x: 29, y: 11, width: 5, height: 3.5)).fill()        // guancia
        dark.setFill()
        NSBezierPath(ovalIn: CGRect(x: 36.6, y: 13, width: 1.6, height: 1.6)).fill()    // naso
        NSBezierPath(ovalIn: CGRect(x: 31.5, y: 15.5, width: 1.4, height: 1.4)).fill()  // occhio
    }
}

// MARK: - Cincia e mangiatoia

/// I semi nella mangiatoia: un clic la riempie, la cincia ne becca uno ogni `Tuning.titPeck` secondi.
nonisolated struct SeedTray: Equatable {
    private(set) var seeds = 0
    private var clock: CGFloat = 0

    mutating func fill() {
        seeds = Tuning.feederSeeds
        clock = 0
    }

    /// true = la cincia ha appena beccato un seme.
    mutating func step(dt: CGFloat) -> Bool {
        guard seeds > 0 else { return false }
        clock += dt
        guard clock >= Tuning.titPeck else { return false }
        clock -= Tuning.titPeck
        seeds -= 1
        return true
    }
}

/// La mangiatoia su un palo: vuota all'inizio; un clic mette i semi e arriva la cincia, che li becca e se ne va.
final class Feeder: Figure {
    private(set) var tray = SeedTray()
    private let tit = SKSpriteNode(texture: Feeder.titTexture)
    private let seedDots = SKNode()

    var titIsHere: Bool { tray.seeds > 0 }

    init(at position: CGPoint) {
        super.init(kind: .tit, texture: Self.texture, at: position)
        tit.size = Self.titTexture.size()
        tit.anchorPoint = CGPoint(x: 0.5, y: 0)
        tit.position = Self.perch
        tit.zPosition = 0.02
        tit.alpha = 0
        node.addChild(tit)
        seedDots.zPosition = 0.01
        node.addChild(seedDots)
    }

    override func clicked() {
        tray.fill()
        drawSeeds()
        // Ferma il volo via ancora in corso, se no al frame dopo la cincia torna invisibile.
        tit.removeAllActions()
        tit.position = Self.perch
        tit.alpha = 1
        SoundBoard.shared.play("cincia")
    }

    override func step(dt: CGFloat) {
        guard tray.step(dt: dt) else { return }
        drawSeeds()
        if !calm { tit.run(.sequence([.rotate(toAngle: -0.35, duration: 0.08), .rotate(toAngle: 0, duration: 0.12)])) }
        guard !titIsHere else { return }
        // Finiti i semi vola via (con Riduci movimento sparisce e basta).
        let away: SKAction = calm ? .fadeOut(withDuration: 0.3) : .group([.fadeOut(withDuration: 0.5), .moveBy(x: 30, y: 20, duration: 0.5)])
        tit.run(.sequence([away, .move(to: Self.perch, duration: 0)]))
    }

    private func drawSeeds() {
        seedDots.removeAllChildren()
        for i in 0..<tray.seeds {
            let seed = SKSpriteNode(color: NSColor(calibratedRed: 0.35, green: 0.25, blue: 0.15, alpha: 1), size: CGSize(width: 2.5, height: 2))
            seed.position = CGPoint(x: -9 + CGFloat(i) * 2.8, y: 42)
            seedDots.addChild(seed)
        }
    }

    /// Dove si posa la cincia, rispetto ai piedi della mangiatoia: sul bordo destro del vassoio.
    private static let perch = CGPoint(x: 6, y: 41)

    private static let wood = NSColor(calibratedRed: 0.5, green: 0.33, blue: 0.2, alpha: 1)

    /// Il palo, il vassoio e il tettuccio con un po' di neve sopra.
    private static let texture = drawnTexture(size: CGSize(width: 30, height: 60)) { _ in
        wood.setFill()
        NSBezierPath(rect: CGRect(x: 13.5, y: 0, width: 3, height: 40)).fill()
        NSBezierPath(rect: CGRect(x: 4, y: 38, width: 22, height: 3)).fill()             // vassoio
        NSBezierPath(rect: CGRect(x: 6, y: 41, width: 1.5, height: 10)).fill()           // i paletti del tetto
        NSBezierPath(rect: CGRect(x: 22.5, y: 41, width: 1.5, height: 10)).fill()
        NSColor(calibratedRed: 0.6, green: 0.2, blue: 0.15, alpha: 1).setFill()
        let roof = NSBezierPath()
        roof.move(to: CGPoint(x: 1, y: 50)); roof.line(to: CGPoint(x: 29, y: 50)); roof.line(to: CGPoint(x: 15, y: 58)); roof.close()
        roof.fill()
        NSColor.white.setFill()
        NSBezierPath(ovalIn: CGRect(x: 8, y: 54, width: 14, height: 5)).fill()
    }

    /// La cincia, guarda a sinistra (verso i semi): testa nera, guancia bianca, petto giallo, dorso verde-grigio.
    private static let titTexture = drawnTexture(size: CGSize(width: 14, height: 11)) { _ in
        NSColor(calibratedRed: 0.42, green: 0.5, blue: 0.42, alpha: 1).setFill()
        NSBezierPath(ovalIn: CGRect(x: 6, y: 3, width: 8, height: 4)).fill()             // coda e dorso
        NSColor(calibratedRed: 0.98, green: 0.82, blue: 0.2, alpha: 1).setFill()
        NSBezierPath(ovalIn: CGRect(x: 3, y: 1, width: 8, height: 7)).fill()             // petto
        NSColor(white: 0.1, alpha: 1).setFill()
        NSBezierPath(ovalIn: CGRect(x: 1.5, y: 5.5, width: 6, height: 5.5)).fill()       // testa
        NSColor.white.setFill()
        NSBezierPath(ovalIn: CGRect(x: 3, y: 6, width: 3.5, height: 2.6)).fill()         // guancia
        NSColor(white: 0.2, alpha: 1).setFill()
        let beak = NSBezierPath()
        beak.move(to: CGPoint(x: 1.8, y: 8)); beak.line(to: CGPoint(x: 0, y: 7.4)); beak.line(to: CGPoint(x: 1.8, y: 7)); beak.close()
        beak.fill()
        NSBezierPath(rect: CGRect(x: 6, y: 0, width: 0.8, height: 1.5)).fill()          // zampe
        NSBezierPath(rect: CGRect(x: 8, y: 0, width: 0.8, height: 1.5)).fill()
    }
}

// MARK: - Baita

/// La baita col camino: un clic accende il fuoco (la finestra si scalda, esce il fumo), un altro lo spegne.
final class Cabin: Figure {
    private(set) var isLit = false
    private let glow = SKSpriteNode(texture: glowTexture(warmLight, diameter: 40))
    private var smokeClock: CGFloat = 0

    init(at position: CGPoint) {
        super.init(kind: .cabin, texture: Self.dark, at: position)
        glow.blendMode = .add
        glow.position = CGPoint(x: -10, y: 12.5)   // davanti alla finestra (i figli sono rispetto ai piedi)
        glow.zPosition = 0.01
        glow.alpha = 0
        node.addChild(glow)
    }

    override func clicked() {
        isLit.toggle()
        node.texture = isLit ? Self.lit : Self.dark
        glow.alpha = isLit ? 0.7 : 0
        smokeClock = Tuning.smokeInterval   // il primo sbuffo subito
        SoundBoard.shared.play("baita")
    }

    override func step(dt: CGFloat) {
        // Il fumo sale e si allarga: è movimento, con Riduci movimento no.
        guard isLit, !calm else { return }
        smokeClock += dt
        guard smokeClock >= Tuning.smokeInterval else { return }
        smokeClock = 0
        let puff = SKSpriteNode(texture: Self.puff)
        puff.name = "smoke"
        puff.alpha = 0.55
        puff.position = CGPoint(x: 12, y: 46)   // sopra il comignolo
        puff.zPosition = -0.01
        node.addChild(puff)
        puff.run(.sequence([
            .group([.moveBy(x: .random(in: 4...12), y: 34, duration: 2.4), .scale(to: 2.2, duration: 2.4), .fadeOut(withDuration: 2.4)]),
            .removeFromParent(),
        ]))
    }

    private static let puff = glowTexture(NSColor(white: 0.85, alpha: 0.9), diameter: 10)

    private static func cabin(windowColor: NSColor) -> SKTexture {
        drawnTexture(size: CGSize(width: 54, height: 46)) { _ in
            NSColor(calibratedRed: 0.4, green: 0.26, blue: 0.16, alpha: 1).setFill()
            NSBezierPath(rect: CGRect(x: 36, y: 26, width: 6, height: 18)).fill()   // camino
            NSColor(calibratedRed: 0.55, green: 0.36, blue: 0.22, alpha: 1).setFill()
            NSBezierPath(rect: CGRect(x: 5, y: 0, width: 44, height: 26)).fill()    // muri
            NSColor(calibratedRed: 0.42, green: 0.27, blue: 0.16, alpha: 1).setStroke()
            for y in stride(from: 5.0, to: 26, by: 5) {                               // tronchi
                let log = NSBezierPath()
                log.move(to: CGPoint(x: 5, y: y)); log.line(to: CGPoint(x: 49, y: y))
                log.lineWidth = 0.8
                log.stroke()
            }
            NSColor(calibratedRed: 0.3, green: 0.18, blue: 0.1, alpha: 1).setFill()
            NSBezierPath(rect: CGRect(x: 32, y: 0, width: 9, height: 15)).fill()    // porta
            windowColor.setFill()
            NSBezierPath(rect: CGRect(x: 12, y: 8, width: 10, height: 9)).fill()    // finestra
            NSColor.white.setFill()
            let roof = NSBezierPath()                                                 // tetto innevato
            roof.move(to: CGPoint(x: 0, y: 25)); roof.line(to: CGPoint(x: 54, y: 25)); roof.line(to: CGPoint(x: 27, y: 42)); roof.close()
            roof.fill()
            NSBezierPath(rect: CGRect(x: 35, y: 42, width: 8, height: 3)).fill()     // neve sul camino
        }
    }

    private static let dark = cabin(windowColor: NSColor(calibratedRed: 0.2, green: 0.22, blue: 0.3, alpha: 1))
    private static let lit = cabin(windowColor: NSColor(calibratedRed: 1, green: 0.78, blue: 0.4, alpha: 1))
}

// MARK: - Lanterna

/// La lanterna: un clic la accende (fiamma e alone che tremolano un po'), un altro la spegne.
final class Lantern: Figure {
    private(set) var isLit = false
    private let halo = SKSpriteNode(texture: glowTexture(warmLight, diameter: 70))
    private var flicker: CGFloat = 0

    init(at position: CGPoint) {
        super.init(kind: .lantern, texture: Self.off, at: position)
        halo.blendMode = .add
        halo.position = CGPoint(x: 0, y: 11)   // intorno alla fiamma
        halo.zPosition = -0.01
        halo.alpha = 0
        node.addChild(halo)
    }

    override func clicked() {
        isLit.toggle()
        node.texture = isLit ? Self.on : Self.off
        halo.alpha = isLit ? Tuning.flameGlow : 0
        SoundBoard.shared.play("lanterna")
    }

    override func step(dt: CGFloat) {
        guard isLit, !calm else { return }
        flicker += dt
        halo.alpha = Tuning.flameGlow * flameFlicker(flicker)
    }

    private static func lantern(flame: Bool) -> SKTexture {
        drawnTexture(size: CGSize(width: 16, height: 28)) { _ in
            let iron = NSColor(white: 0.18, alpha: 1)
            iron.setFill()
            NSBezierPath(rect: CGRect(x: 2, y: 0, width: 12, height: 3)).fill()      // base
            NSBezierPath(rect: CGRect(x: 1, y: 19, width: 14, height: 3)).fill()     // cappello
            let cap = NSBezierPath()
            cap.move(to: CGPoint(x: 3, y: 22)); cap.line(to: CGPoint(x: 13, y: 22)); cap.line(to: CGPoint(x: 8, y: 25)); cap.close()
            cap.fill()
            iron.setStroke()
            let ring = NSBezierPath(ovalIn: CGRect(x: 5.5, y: 24, width: 5, height: 4))
            ring.lineWidth = 1
            ring.stroke()
            (flame ? NSColor(calibratedRed: 1, green: 0.85, blue: 0.55, alpha: 0.55) : NSColor(white: 0.85, alpha: 0.35)).setFill()
            NSBezierPath(rect: CGRect(x: 3, y: 3, width: 10, height: 16)).fill()     // vetro
            for x in [2.0, 7.25, 12.5] { NSBezierPath(rect: CGRect(x: x, y: 3, width: 1.5, height: 16)).fill() }
            guard flame else { return }
            NSColor(calibratedRed: 1, green: 0.62, blue: 0.15, alpha: 1).setFill()
            NSBezierPath(ovalIn: CGRect(x: 5.5, y: 6, width: 5, height: 9)).fill()
            NSColor(calibratedRed: 1, green: 0.95, blue: 0.7, alpha: 1).setFill()
            NSBezierPath(ovalIn: CGRect(x: 6.8, y: 7, width: 2.4, height: 5)).fill()
        }
    }

    private static let off = lantern(flame: false)
    private static let on = lantern(flame: true)
}

// MARK: - Renna

/// La renna: cammina piano avanti e indietro sopra la sua finestra; col cursore vicino il naso si illumina.
final class Reindeer: Figure {
    override var walkSpeed: CGFloat? { Tuning.reindeerWalk }
    private let nose = SKSpriteNode(texture: glowTexture(NSColor(calibratedRed: 1, green: 0.2, blue: 0.15, alpha: 1), diameter: 26))
    private var gait: CGFloat = 0

    init(at position: CGPoint) {
        super.init(kind: .reindeer, texture: Self.texture, at: position)
        friction = 0
        nose.blendMode = .add
        nose.position = CGPoint(x: 21, y: 22)
        nose.zPosition = 0.01
        nose.alpha = 0
        node.addChild(nose)
    }

    /// Quanto è acceso il naso (0…1) con il cursore a `distance` pt.
    nonisolated static func noseGlow(distance: CGFloat) -> CGFloat {
        max(0, 1 - distance / Tuning.reindeerNoseReach)
    }

    /// Dove è il naso, in coordinate della scena.
    var noseInScene: CGPoint {
        CGPoint(x: body.position.x + 21 * heading, y: body.position.y + 22)
    }

    func light(mouse: CGPoint) {
        nose.alpha = Self.noseGlow(distance: hypot(mouse.x - noseInScene.x, mouse.y - noseInScene.y))
    }

    override func step(dt: CGFloat) {
        node.xScale = heading
        guard !calm, body.isResting, abs(body.velocity.dx) > 1 else { node.zRotation = 0; return }
        gait += dt * abs(body.velocity.dx) / 5
        node.zRotation = sin(gait) * 0.03
    }

    override func clicked() {
        heading = -heading   // un clic la fa girare
        SoundBoard.shared.play("renna")
    }

    /// Guarda a destra: corpo marrone, pancia chiara, corna, naso (che si illumina con un alone a parte).
    private static let texture = drawnTexture(size: CGSize(width: 46, height: 34)) { _ in
        let brown = NSColor(calibratedRed: 0.52, green: 0.35, blue: 0.22, alpha: 1)
        let antler = NSColor(calibratedRed: 0.38, green: 0.26, blue: 0.16, alpha: 1)
        brown.setStroke()
        for (from, to) in [(9.0, 8.0), (13, 14), (27, 26), (31, 32)] {
            let leg = NSBezierPath()
            leg.move(to: CGPoint(x: from, y: 11)); leg.line(to: CGPoint(x: to, y: 0))
            leg.lineWidth = 2.2
            leg.stroke()
        }
        brown.setFill()
        NSBezierPath(ovalIn: CGRect(x: 5, y: 9, width: 30, height: 12)).fill()            // corpo
        NSColor(calibratedRed: 0.9, green: 0.82, blue: 0.7, alpha: 1).setFill()
        NSBezierPath(ovalIn: CGRect(x: 12, y: 9, width: 16, height: 5)).fill()            // pancia
        NSColor(white: 0.95, alpha: 1).setFill()
        NSBezierPath(ovalIn: CGRect(x: 3, y: 15, width: 5, height: 5)).fill()             // coda
        brown.setStroke()
        let neck = NSBezierPath()
        neck.move(to: CGPoint(x: 31, y: 17)); neck.line(to: CGPoint(x: 37, y: 25))
        neck.lineWidth = 6
        neck.stroke()
        brown.setFill()
        NSBezierPath(ovalIn: CGRect(x: 35, y: 21, width: 10, height: 7)).fill()           // testa
        NSColor.systemRed.setFill()
        NSBezierPath(ovalIn: CGRect(x: 42.5, y: 20.5, width: 3.5, height: 3.5)).fill()    // naso
        NSColor(white: 0.1, alpha: 1).setFill()
        NSBezierPath(ovalIn: CGRect(x: 39, y: 25, width: 1.5, height: 1.5)).fill()        // occhio
        antler.setStroke()
        let horns = NSBezierPath()
        horns.move(to: CGPoint(x: 37, y: 27)); horns.line(to: CGPoint(x: 33, y: 34))
        horns.move(to: CGPoint(x: 35, y: 31)); horns.line(to: CGPoint(x: 30, y: 32))
        horns.move(to: CGPoint(x: 39, y: 27)); horns.line(to: CGPoint(x: 41, y: 34))
        horns.move(to: CGPoint(x: 40, y: 31)); horns.line(to: CGPoint(x: 44, y: 32))
        horns.lineWidth = 1.4
        horns.stroke()
    }
}
