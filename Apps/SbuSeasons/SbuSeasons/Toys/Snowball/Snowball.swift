import AppKit
import SpriteKit

/// Una palla di neve: si fa tenendo ⌥ e passando il cursore sulla neve posata (`SeasonScene.roll(at:)`),
/// si lancia col mouse, rimbalza un po' e rotola lungo i bordi. Tre vicine diventano un pupazzo.
final class Snowball: Toy {
    static let radius: CGFloat = 9
    /// Il disegno della palla, al centro: gira mentre rotola (il `node` ha l'àncora in basso, girerebbe sul piede).
    private let ball = SKSpriteNode(texture: Snowball.texture)

    init(at position: CGPoint) {
        let size = CGSize(width: Self.radius * 2, height: Self.radius * 2)
        super.init(node: SKSpriteNode(color: .clear, size: size), at: position)
        ball.size = size
        ball.position = CGPoint(x: 0, y: Self.radius)
        node.addChild(ball)
        bounce = 0.3
        friction = Tuning.snowballFriction
    }

    /// Quanto ha girato, in radianti.
    var spin: CGFloat { ball.zRotation }

    override func step(dt: CGFloat) {
        ball.zRotation -= body.velocity.dx * dt / Self.radius
    }

    private static let texture = drawnTexture(size: CGSize(width: radius * 2, height: radius * 2)) { rect in
        let snow = Quaderno.paper.lightColor
        snow.setFill()
        NSBezierPath(ovalIn: rect.insetBy(dx: 0.5, dy: 0.5)).fill()
        // Un po' d'ombra in basso e un granello più scuro: senza, la palla non si vede girare.
        snow.shadow(withLevel: 0.12)?.setFill()
        NSBezierPath(ovalIn: CGRect(x: rect.midX - 4, y: 1.5, width: 8, height: 4)).fill()
        NSBezierPath(ovalIn: CGRect(x: rect.midX + 2, y: rect.midY + 2, width: 3, height: 3)).fill()
    }
}

/// Le posizioni di tre palle tutte vicine tra loro (entro `distance`), o nil. Le prime che trova.
nonisolated func snowmanTrio(_ balls: [CGPoint], within distance: CGFloat) -> [Int]? {
    func near(_ a: Int, _ b: Int) -> Bool { hypot(balls[a].x - balls[b].x, balls[a].y - balls[b].y) <= distance }
    for a in balls.indices {
        for b in balls.indices where b > a && near(a, b) {
            for c in balls.indices where c > b && near(a, c) && near(b, c) { return [a, b, c] }
        }
    }
    return nil
}

/// Una texture disegnata una volta con AppKit (origine in basso a sinistra). La usano tutti gli oggetti.
func drawnTexture(size: CGSize, _ draw: @escaping (CGRect) -> Void) -> SKTexture {
    SKTexture(image: NSImage(size: size, flipped: false) { rect in
        draw(rect)
        return true
    })
}
