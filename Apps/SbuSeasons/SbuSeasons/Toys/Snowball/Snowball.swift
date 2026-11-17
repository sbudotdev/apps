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

/// Il pupazzo di neve: nasce da tre palle vicine. Non fa niente, si sposta e si lancia come gli altri oggetti.
final class Snowman: Toy {
    init(at position: CGPoint) {
        let node = SKSpriteNode(texture: Self.texture)
        node.size = Self.texture.size()
        super.init(node: node, at: position)
    }

    private static let texture = drawnTexture(size: CGSize(width: 30, height: 46)) { _ in
        let snow = Quaderno.paper.lightColor
        let shade = snow.shadow(withLevel: 0.12) ?? snow
        // Tre palle, dal basso: 26, 20, 14 pt.
        for ball in [CGRect(x: 2, y: 0, width: 26, height: 22), CGRect(x: 5, y: 17, width: 20, height: 17),
                     CGRect(x: 8, y: 31, width: 14, height: 14)] {
            snow.setFill()
            NSBezierPath(ovalIn: ball).fill()
            shade.setFill()
            NSBezierPath(ovalIn: CGRect(x: ball.midX - ball.width * 0.3, y: ball.minY + 0.5,
                                        width: ball.width * 0.6, height: 3)).fill()
        }
        let coal = NSColor(white: 0.15, alpha: 1)
        coal.setFill()
        for eye in [CGPoint(x: 12.5, y: 39), CGPoint(x: 17.5, y: 39), CGPoint(x: 15, y: 28), CGPoint(x: 15, y: 23)] {
            NSBezierPath(ovalIn: CGRect(x: eye.x - 1, y: eye.y - 1, width: 2, height: 2)).fill()
        }
        // Il naso, una carota che guarda a destra.
        let nose = NSBezierPath()
        nose.move(to: CGPoint(x: 15, y: 37.5))
        nose.line(to: CGPoint(x: 22, y: 36.5))
        nose.line(to: CGPoint(x: 15, y: 35.5))
        nose.close()
        NSColor.systemOrange.setFill()
        nose.fill()
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

/// Una texture disegnata una volta con AppKit (origine in basso a sinistra).
private func drawnTexture(size: CGSize, _ draw: @escaping (CGRect) -> Void) -> SKTexture {
    SKTexture(image: NSImage(size: size, flipped: false) { rect in
        draw(rect)
        return true
    })
}
