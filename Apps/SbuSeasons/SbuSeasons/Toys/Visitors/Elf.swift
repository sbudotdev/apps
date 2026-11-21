import AppKit
import SpriteKit

/// L'elfo (SBU-187): esce dalla neve, rotola tre palle una accanto all'altra (diventano un pupazzo, che resta)
/// e se ne va di lato. Non si trascina. Lo muove `SeasonScene.stepElf`; quando passa lo decide `Visitors`.
final class Elf: Toy {
    /// 1 = le palle a destra e se ne va verso destra.
    let heading: CGFloat
    /// Da quanto è uscito dalla neve (s).
    var clock: CGFloat = 0
    /// Le palle già rotolate.
    var balls = 0
    private var gait: CGFloat = 0

    init(at position: CGPoint, heading: CGFloat) {
        self.heading = heading
        let node = SKSpriteNode(texture: Self.texture)
        node.size = Self.texture.size()
        super.init(node: node, at: position)
        friction = 0
        isDraggable = false
        staysOnScreen = false
    }

    /// Ha finito le palle: se ne va.
    var isLeaving: Bool { balls >= 3 && clock >= Tuning.elfRise + Tuning.elfRollInterval * 4 }

    override func step(dt: CGFloat) {
        node.xScale = heading
        let calm = (node.scene as? SeasonScene)?.reduceMotion ?? true
        // Esce dalla neve: cresce dal basso (con Riduci movimento compare piano).
        let risen = min(1, clock / Tuning.elfRise)
        node.yScale = calm ? 1 : risen
        node.alpha = calm ? risen : 1
        guard !calm, abs(body.velocity.dx) > 1 else { node.zRotation = 0; return }
        gait += dt * abs(body.velocity.dx) / 5
        node.zRotation = sin(gait) * 0.08
    }

    // MARK: - Disegno

    private static let texture = drawnTexture(size: CGSize(width: 14, height: 22)) { _ in
        let green = NSColor(calibratedRed: 0.13, green: 0.5, blue: 0.28, alpha: 1)
        let red = NSColor(calibratedRed: 0.78, green: 0.12, blue: 0.16, alpha: 1)
        // Gambe a righe, la tunica verde con la cintura, la testa, il cappello a punta col pompon. Guarda a destra.
        red.setFill()
        for x in [4.0, 7.5] { NSBezierPath(rect: CGRect(x: x, y: 0, width: 2.5, height: 5)).fill() }
        let tunic = NSBezierPath()
        tunic.move(to: CGPoint(x: 2, y: 4))
        tunic.line(to: CGPoint(x: 12, y: 4))
        tunic.line(to: CGPoint(x: 10, y: 12))
        tunic.line(to: CGPoint(x: 4, y: 12))
        tunic.close()
        green.setFill()
        tunic.fill()
        NSColor(white: 0.15, alpha: 1).setFill()
        NSBezierPath(rect: CGRect(x: 3, y: 7, width: 8, height: 1.2)).fill()
        NSColor(calibratedRed: 0.98, green: 0.85, blue: 0.72, alpha: 1).setFill()
        NSBezierPath(ovalIn: CGRect(x: 4, y: 11, width: 6, height: 6)).fill()
        NSBezierPath(ovalIn: CGRect(x: 9.2, y: 13, width: 1.6, height: 2.4)).fill()   // l'orecchio a punta
        NSColor(white: 0.15, alpha: 1).setFill()
        NSBezierPath(ovalIn: CGRect(x: 8, y: 14, width: 1, height: 1)).fill()
        let hat = NSBezierPath()
        hat.move(to: CGPoint(x: 3.5, y: 15.5))
        hat.line(to: CGPoint(x: 10.5, y: 15.5))
        hat.line(to: CGPoint(x: 1.5, y: 20.5))
        hat.close()
        red.setFill()
        hat.fill()
        NSColor.white.setFill()
        NSBezierPath(ovalIn: CGRect(x: 0, y: 19.5, width: 2.5, height: 2.5)).fill()
    }
}
