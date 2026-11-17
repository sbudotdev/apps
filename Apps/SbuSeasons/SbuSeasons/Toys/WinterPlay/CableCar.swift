import AppKit
import SpriteKit

/// La funivia: un palo sul fondo dello schermo (la stazione) e un cavo fino a un gancio. Il gancio è l'oggetto:
/// lo trascini sul bordo di una finestra (o sul Dock) e la cabina corre avanti e indietro sul cavo.
/// Con il gancio più in basso della cima del palo la cabina resta alla stazione.
final class CableCar: Toy {
    /// La base del palo, in coordinate della scena.
    let station: CGPoint
    /// Dov'è la cabina sul cavo: 0 = al palo, 1 = al gancio.
    private(set) var ride: CGFloat = 0
    private var direction: CGFloat = 1
    private let pylon = SKSpriteNode(texture: CableCar.pylonTexture)
    private let cabin = SKSpriteNode(texture: CableCar.cabinTexture)
    private let cable = SKShapeNode()
    /// Dove stava il gancio quando si è disegnato il cavo: ridisegnarlo a ogni fotogramma costa CPU.
    private var drawnAt: CGPoint?

    init(station: CGPoint, hook: CGPoint) {
        self.station = station
        let node = SKSpriteNode(texture: Self.hookTexture)
        node.size = Self.hookTexture.size()
        super.init(node: node, at: hook)
        // I pezzi seguono il gancio (sono suoi figli): le loro posizioni sono rispetto ai piedi del gancio.
        pylon.anchorPoint = CGPoint(x: 0.5, y: 0)
        pylon.size = CGSize(width: 10, height: Tuning.cablePylonHeight + 2)
        cable.strokeColor = NSColor(white: 0.2, alpha: 1)
        cable.lineWidth = 1.5
        cable.zPosition = -0.01
        cabin.anchorPoint = CGPoint(x: 0.5, y: 1)
        cabin.size = Self.cabinTexture.size()
        cabin.zPosition = 0.01
        for part in [pylon, cable, cabin] { node.addChild(part) }
    }

    /// Il gancio è più in alto del palo e poggia su un bordo: la cabina corre.
    var isRunning: Bool { body.isResting && hookPoint.y > pylonTop.y }

    private var pylonTop: CGPoint { CGPoint(x: station.x, y: station.y + Tuning.cablePylonHeight) }
    private var hookPoint: CGPoint { CGPoint(x: body.position.x, y: body.position.y + node.size.height - 3) }

    override func step(dt: CGFloat) {
        let feet = body.position
        let top = CGPoint(x: pylonTop.x - feet.x, y: pylonTop.y - feet.y)
        let end = CGPoint(x: hookPoint.x - feet.x, y: hookPoint.y - feet.y)
        if drawnAt != feet {
            drawnAt = feet
            pylon.position = CGPoint(x: station.x - feet.x, y: station.y - feet.y)
            let path = CGMutablePath()
            path.move(to: top)
            path.addLine(to: end)
            cable.path = path
        }
        let length = max(1, hypot(end.x - top.x, end.y - top.y))
        if isRunning {
            ride += direction * Tuning.cableSpeed * dt / length
            if ride >= 1 || ride <= 0 {
                ride = min(1, max(0, ride))
                direction = -direction
            }
        } else {
            ride = 0
            direction = 1
        }
        cabin.position = CGPoint(x: top.x + (end.x - top.x) * ride, y: top.y + (end.y - top.y) * ride)
    }

    private static let hookTexture = drawnTexture(size: CGSize(width: 12, height: 18)) { _ in
        // Un gancio d'ottone: l'anello in alto, il gambo, la curva in basso.
        let brass = NSColor(calibratedRed: 0.78, green: 0.6, blue: 0.25, alpha: 1)
        brass.setStroke()
        let hook = NSBezierPath()
        hook.lineWidth = 2.2
        hook.appendOval(in: CGRect(x: 3.5, y: 12.5, width: 5, height: 4.5))
        hook.move(to: CGPoint(x: 6, y: 12.5))
        hook.line(to: CGPoint(x: 6, y: 6))
        hook.appendArc(withCenter: CGPoint(x: 6, y: 4.5), radius: 3.5, startAngle: 90, endAngle: 0, clockwise: false)
        hook.stroke()
    }

    private static let pylonTexture = drawnTexture(size: CGSize(width: 10, height: 62)) { _ in
        NSColor(white: 0.3, alpha: 1).setFill()
        NSBezierPath(rect: CGRect(x: 4, y: 0, width: 2, height: 60)).fill()
        NSBezierPath(rect: CGRect(x: 0, y: 58, width: 10, height: 3)).fill()
    }

    private static let cabinTexture = drawnTexture(size: CGSize(width: 22, height: 26)) { _ in
        // Il braccio che pende dal cavo e la cabina rossa con due finestrini.
        NSColor(white: 0.25, alpha: 1).setFill()
        NSBezierPath(rect: CGRect(x: 10, y: 15, width: 2, height: 11)).fill()
        NSColor.systemRed.setFill()
        NSBezierPath(roundedRect: CGRect(x: 1, y: 0, width: 20, height: 16), xRadius: 3, yRadius: 3).fill()
        NSColor(calibratedRed: 0.75, green: 0.88, blue: 0.95, alpha: 1).setFill()
        for x in [4.0, 12] { NSBezierPath(rect: CGRect(x: x, y: 7, width: 6, height: 6)).fill() }
    }
}
