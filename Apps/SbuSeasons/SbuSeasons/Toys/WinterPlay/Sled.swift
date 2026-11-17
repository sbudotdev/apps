import AppKit
import SpriteKit

/// Lo slittino: si lancia trascinandolo (o con un clic, che lo spinge avanti), frena pochissimo e scende
/// di bordo in bordo lungo le finestre: la pista sono i bordi stessi. Guarda dove va.
final class Sled: Toy {
    init(at position: CGPoint) {
        let node = SKSpriteNode(texture: Self.texture)
        node.size = Self.texture.size()
        super.init(node: node, at: position)
        friction = Tuning.sledFriction
        bounce = 0.15
    }

    override func step(dt: CGFloat) {
        if abs(body.velocity.dx) > 1 { node.xScale = body.velocity.dx < 0 ? -1 : 1 }
    }

    override func clicked() {
        // Con Riduci movimento i lanci cadono dritti: anche il clic non lo spinge (QA SBU-63).
        guard (node.scene as? SeasonScene)?.reduceMotion != true else { return }
        body.velocity.dx = Tuning.sledPush * node.xScale
        SoundBoard.shared.play("slittino")
    }

    private static let texture = drawnTexture(size: CGSize(width: 34, height: 14)) { _ in
        // Il pattino curvo davanti (a destra), le due assi, il sedile rosso.
        let runner = NSBezierPath()
        runner.move(to: CGPoint(x: 1, y: 1.5))
        runner.line(to: CGPoint(x: 27, y: 1.5))
        runner.curve(to: CGPoint(x: 32, y: 8), controlPoint1: CGPoint(x: 32, y: 1.5), controlPoint2: CGPoint(x: 33, y: 5))
        runner.lineWidth = 2
        NSColor(white: 0.25, alpha: 1).setStroke()
        runner.stroke()
        NSColor(calibratedRed: 0.55, green: 0.36, blue: 0.2, alpha: 1).setFill()
        for x in [7.0, 21] { NSBezierPath(rect: CGRect(x: x, y: 2, width: 2.5, height: 5)).fill() }
        NSColor.systemRed.setFill()
        NSBezierPath(roundedRect: CGRect(x: 3, y: 6.5, width: 24, height: 5), xRadius: 2, yRadius: 2).fill()
    }
}
