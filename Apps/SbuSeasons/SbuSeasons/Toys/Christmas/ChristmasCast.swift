import AppKit
import SpriteKit

/// Babbo Natale con la slitta e due renne: attraversa il cielo e, se lo porta, lascia cadere il regalo in `dropX`.
/// Non è un oggetto con cui giocare: vola, non si prende. Lo muove `SeasonScene.stepChristmas`.
final class Santa {
    let node = SKSpriteNode(texture: Santa.texture)
    /// 1 = verso destra, -1 = verso sinistra.
    let heading: CGFloat
    let carriesGift: Bool
    /// Dove lascia cadere il regalo (x della scena). nil = già lasciato, o non lo porta.
    var dropX: CGFloat?
    /// L'altezza a cui vola (ci ondeggia intorno).
    var altitude: CGFloat = 0
    /// La letterina da prendere al volo (SBU-178).
    weak var pickup: SKNode?

    init(heading: CGFloat, carriesGift: Bool) {
        self.heading = heading
        self.carriesGift = carriesGift
        node.size = Santa.texture.size()
        node.xScale = heading
        node.zPosition = 1.8   // davanti ai fiocchi, dietro gli oggetti
    }

    private static let texture = drawnTexture(size: CGSize(width: 118, height: 36)) { _ in
        let brown = NSColor(calibratedRed: 0.5, green: 0.33, blue: 0.2, alpha: 1)
        let antler = NSColor(calibratedRed: 0.36, green: 0.24, blue: 0.14, alpha: 1)
        // Le redini, dalla slitta al muso della prima renna.
        let reins = NSBezierPath()
        reins.move(to: CGPoint(x: 34, y: 20))
        reins.curve(to: CGPoint(x: 111, y: 24), controlPoint1: CGPoint(x: 60, y: 14), controlPoint2: CGPoint(x: 90, y: 16))
        reins.lineWidth = 1
        NSColor(white: 0.85, alpha: 0.9).setStroke()
        reins.stroke()
        // Due renne in fila, guardano a destra: corpo, zampe, collo, testa, corna.
        for x in [52.0, 86] {
            brown.setFill()
            NSBezierPath(ovalIn: CGRect(x: x, y: 11, width: 22, height: 10)).fill()
            brown.setStroke()
            for (from, to) in [(x + 3, x - 1), (x + 7, x + 9), (x + 16, x + 13), (x + 19, x + 23)] {
                let leg = NSBezierPath()
                leg.move(to: CGPoint(x: from, y: 13))
                leg.line(to: CGPoint(x: to, y: 4))
                leg.lineWidth = 1.6
                leg.stroke()
            }
            let neck = NSBezierPath()
            neck.move(to: CGPoint(x: x + 18, y: 17))
            neck.line(to: CGPoint(x: x + 23, y: 24))
            neck.lineWidth = 4
            neck.stroke()
            NSBezierPath(ovalIn: CGRect(x: x + 21, y: 22, width: 9, height: 6)).fill()
            antler.setStroke()
            let horns = NSBezierPath()
            horns.move(to: CGPoint(x: x + 23, y: 27)); horns.line(to: CGPoint(x: x + 20, y: 33))
            horns.move(to: CGPoint(x: x + 21, y: 30)); horns.line(to: CGPoint(x: x + 17, y: 31))
            horns.move(to: CGPoint(x: x + 25, y: 27)); horns.line(to: CGPoint(x: x + 26, y: 33))
            horns.lineWidth = 1.2
            horns.stroke()
        }
        // Il naso rosso della renna davanti.
        NSColor.systemRed.setFill()
        NSBezierPath(ovalIn: CGRect(x: 114, y: 23, width: 4, height: 4)).fill()
        // La slitta: pattino curvo, cassa rossa con il bordo d'oro.
        let runner = NSBezierPath()
        runner.move(to: CGPoint(x: 2, y: 4))
        runner.line(to: CGPoint(x: 36, y: 4))
        runner.curve(to: CGPoint(x: 42, y: 11), controlPoint1: CGPoint(x: 41, y: 4), controlPoint2: CGPoint(x: 42, y: 8))
        runner.lineWidth = 2
        NSColor(white: 0.3, alpha: 1).setStroke()
        runner.stroke()
        NSColor(calibratedRed: 0.75, green: 0.1, blue: 0.12, alpha: 1).setFill()
        NSBezierPath(roundedRect: CGRect(x: 4, y: 7, width: 32, height: 13), xRadius: 4, yRadius: 4).fill()
        NSColor.systemYellow.setFill()
        NSBezierPath(rect: CGRect(x: 4, y: 18, width: 32, height: 2)).fill()
        // Il sacco dietro e Babbo Natale davanti: giacca rossa, barba bianca, berretto col pon pon.
        NSColor(calibratedRed: 0.55, green: 0.42, blue: 0.3, alpha: 1).setFill()
        NSBezierPath(ovalIn: CGRect(x: 4, y: 17, width: 13, height: 13)).fill()
        NSColor.systemRed.setFill()
        NSBezierPath(ovalIn: CGRect(x: 18, y: 17, width: 13, height: 12)).fill()
        NSColor(calibratedRed: 0.98, green: 0.82, blue: 0.7, alpha: 1).setFill()
        NSBezierPath(ovalIn: CGRect(x: 22, y: 26, width: 8, height: 7)).fill()
        NSColor.white.setFill()
        NSBezierPath(ovalIn: CGRect(x: 23, y: 23, width: 8, height: 6)).fill()
        NSColor.systemRed.setFill()
        let hat = NSBezierPath()
        hat.move(to: CGPoint(x: 21, y: 31)); hat.line(to: CGPoint(x: 31, y: 31)); hat.line(to: CGPoint(x: 21, y: 35.5)); hat.close()
        hat.fill()
        NSColor.white.setFill()
        NSBezierPath(ovalIn: CGRect(x: 18, y: 33, width: 4, height: 3)).fill()
    }
}

/// Il regalo di Babbo Natale: cade su una finestra o sul Dock; un clic lo apre e ne salta fuori un omino di pan di zenzero.
/// Aperto resta qualche secondo, poi sparisce (`Tuning.giftLinger`).
final class Gift: Toy {
    private(set) var isOpen = false
    /// Da quanto è aperto (s).
    private(set) var openFor: CGFloat = 0
    /// Il regalo del trenino (SBU-178): verde, e dentro c'è un oggetto per l'albero o il pupazzo (`ElfPresent`).
    let fromElf: Bool

    init(at position: CGPoint, fromElf: Bool = false) {
        self.fromElf = fromElf
        let closed = fromElf ? Self.elfClosed : Self.closed
        let node = SKSpriteNode(texture: closed)
        node.size = closed.size()
        super.init(node: node, at: position)
        bounce = 0.25
    }

    override func step(dt: CGFloat) {
        guard isOpen else { return }
        openFor += dt
        node.alpha = min(1, max(0, (Tuning.giftLinger - openFor) / 0.5))
    }

    override func clicked() {
        guard !isOpen else { return }
        isOpen = true
        node.texture = fromElf ? Self.elfOpen : Self.open
        SoundBoard.shared.play("regalo")
        guard let scene = node.scene as? SeasonScene else { return }
        if fromElf { scene.unwrapElfGift(self) } else { scene.unwrap(self) }
    }

    private static let red = NSColor(calibratedRed: 0.78, green: 0.12, blue: 0.16, alpha: 1)
    private static let gold = NSColor(calibratedRed: 0.98, green: 0.78, blue: 0.2, alpha: 1)

    private static let green = NSColor(calibratedRed: 0.13, green: 0.45, blue: 0.26, alpha: 1)
    private static let closed = drawnTexture(size: CGSize(width: 22, height: 22)) { _ in drawClosed(box: red, ribbon: gold) }
    private static let open = drawnTexture(size: CGSize(width: 22, height: 22)) { _ in drawOpen(box: red, ribbon: gold) }
    private static let elfClosed = drawnTexture(size: CGSize(width: 22, height: 22)) { _ in drawClosed(box: green, ribbon: red) }
    private static let elfOpen = drawnTexture(size: CGSize(width: 22, height: 22)) { _ in drawOpen(box: green, ribbon: red) }

    private static func drawClosed(box red: NSColor, ribbon gold: NSColor) {
        red.setFill()
        NSBezierPath(rect: CGRect(x: 2, y: 0, width: 18, height: 14)).fill()
        NSBezierPath(rect: CGRect(x: 1, y: 13, width: 20, height: 4)).fill()   // il coperchio
        gold.setFill()
        NSBezierPath(rect: CGRect(x: 9.5, y: 0, width: 3, height: 17)).fill()
        // Il fiocco: due anelli sopra il coperchio.
        gold.setStroke()
        for x in [6.0, 12] {
            let loop = NSBezierPath(ovalIn: CGRect(x: x, y: 16.5, width: 5, height: 4.5))
            loop.lineWidth = 1.5
            loop.stroke()
        }
    }

    private static func drawOpen(box red: NSColor, ribbon gold: NSColor) {
        red.setFill()
        NSBezierPath(rect: CGRect(x: 2, y: 0, width: 18, height: 14)).fill()
        gold.setFill()
        NSBezierPath(rect: CGRect(x: 9.5, y: 0, width: 3, height: 14)).fill()
        // Il coperchio appoggiato di traverso.
        let lid = NSBezierPath(rect: CGRect(x: -10, y: -2, width: 20, height: 4))
        var turn = AffineTransform(translationByX: 15, byY: 18)
        turn.rotate(byDegrees: -25)
        lid.transform(using: turn)
        red.setFill()
        lid.fill()
    }
}

/// L'omino di pan di zenzero: corre avanti e indietro sul suo bordo (di solito il Dock) senza cadere
/// e scappa dal cursore; messo all'angolo salta oltre. Preso con un clic, sparisce. La corsa la decide `run`.
final class GingerbreadMan: Toy {
    /// 1 = verso destra, -1 = verso sinistra.
    var heading: CGFloat = 1
    private var gait: CGFloat = 0

    init(at position: CGPoint) {
        let node = SKSpriteNode(texture: Self.texture)
        node.size = Self.texture.size()
        super.init(node: node, at: position)
        friction = 0
    }

    /// Dove va adesso, sul bordo `span`. Scappa se il cursore è vicino; in fondo al bordo si gira,
    /// e se intanto scappava (è all'angolo) salta.
    nonisolated static func run(x: CGFloat, span: ClosedRange<CGFloat>, heading: CGFloat, mouse: CGPoint, feetY: CGFloat)
        -> (heading: CGFloat, fleeing: Bool, jumps: Bool) {
        let fleeing = hypot(mouse.x - x, mouse.y - (feetY + 12)) < Tuning.gingerbreadFlee
        var heading: CGFloat = fleeing ? (mouse.x > x ? -1 : 1) : heading
        guard !span.contains(x + heading * Tuning.gingerbreadTurn) else { return (heading, fleeing, false) }
        heading = -heading
        return (heading, fleeing, fleeing)
    }

    override func step(dt: CGFloat) {
        node.xScale = heading
        // Corre dondolando; fermo, in aria o con Riduci movimento sta dritto.
        let calm = (node.scene as? SeasonScene)?.reduceMotion ?? false
        guard !calm, body.isResting, abs(body.velocity.dx) > 1 else { node.zRotation = 0; return }
        gait += dt * abs(body.velocity.dx) / 6
        node.zRotation = sin(gait) * 0.15
    }

    override func clicked() {
        SoundBoard.shared.play("omino-preso")
        guard let scene = node.scene as? SeasonScene else { return }
        scene.sparkle(at: CGPoint(x: body.position.x, y: body.position.y + 12))
        scene.remove(self)
    }

    private static let texture = drawnTexture(size: CGSize(width: 18, height: 24)) { _ in
        let dough = NSColor(calibratedRed: 0.72, green: 0.45, blue: 0.22, alpha: 1)
        dough.setFill()
        NSBezierPath(ovalIn: CGRect(x: 4.5, y: 15, width: 9, height: 9)).fill()                       // testa
        NSBezierPath(roundedRect: CGRect(x: 5, y: 6, width: 8, height: 11), xRadius: 3, yRadius: 3).fill()   // corpo
        NSBezierPath(roundedRect: CGRect(x: 0, y: 12, width: 18, height: 4), xRadius: 2, yRadius: 2).fill()  // braccia
        for x in [4.0, 10] { NSBezierPath(roundedRect: CGRect(x: x, y: 0, width: 4, height: 9), xRadius: 2, yRadius: 2).fill() }
        // Glassa: occhi, sorriso, bottoni.
        NSColor.white.setFill()
        for x in [7.0, 10] { NSBezierPath(ovalIn: CGRect(x: x, y: 19.5, width: 1.6, height: 1.6)).fill() }
        let smile = NSBezierPath()
        smile.appendArc(withCenter: CGPoint(x: 9, y: 18.5), radius: 1.8, startAngle: 200, endAngle: 340)
        smile.lineWidth = 0.8
        NSColor.white.setStroke()
        smile.stroke()
        for y in [9.0, 12] { NSBezierPath(ovalIn: CGRect(x: 8.2, y: y, width: 1.6, height: 1.6)).fill() }
        NSColor.systemRed.setFill()
        NSBezierPath(ovalIn: CGRect(x: 8.2, y: 14.6, width: 1.6, height: 1.6)).fill()
    }
}
