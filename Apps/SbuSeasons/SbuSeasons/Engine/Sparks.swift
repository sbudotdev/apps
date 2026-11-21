import AppKit
import SpriteKit

/// Le scintille di una stella cadente che si rompe sul bordo di una finestra (SBU-177): un ventaglio verso l'alto
/// che ricade e si spegne in meno di un secondo. Con Riduci movimento poche, ferme, che si spengono dove sono.
final class Sparks: SKNode {
    private struct Spark {
        let node: SKSpriteNode
        var velocity: CGVector
        var life: CGFloat
        let total: CGFloat
    }
    private var sparks: [Spark] = []
    private static let texture = glowTexture(.white, diameter: 16)

    var count: Int { sparks.count }

    func burst(at point: CGPoint, color: NSColor, calm: Bool) {
        emit(calm ? Tuning.sparksPerBurst / 3 : Tuning.sparksPerBurst, at: point, color: color, calm: calm,
             speed: Tuning.sparkSpeed, life: Tuning.sparkLife, size: 3...7)
    }

    /// Gli schizzi di una goccia di pioggia sul bordo di una finestra (SBU-185): poche goccioline basse e brevi.
    func splash(at point: CGPoint, color: NSColor, calm: Bool) {
        emit(calm ? 2 : Tuning.splashDrops, at: point, color: color, calm: calm,
             speed: Tuning.splashSpeed, life: Tuning.splashLife, size: 2...3.5)
    }

    private func emit(_ count: Int, at point: CGPoint, color: NSColor, calm: Bool, speed: ClosedRange<CGFloat>,
                      life: ClosedRange<CGFloat>, size: ClosedRange<CGFloat>) {
        for _ in 0..<count {
            let node = SKSpriteNode(texture: Self.texture)
            let diameter = CGFloat.random(in: size)
            node.size = CGSize(width: diameter, height: diameter)
            node.color = color
            node.colorBlendFactor = 1
            node.blendMode = .add
            node.position = point
            node.zPosition = 1.6
            addChild(node)
            let angle = CGFloat.random(in: (0.1 * .pi)...(0.9 * .pi))
            let speed = calm ? 0 : CGFloat.random(in: speed)
            let life = CGFloat.random(in: life)
            sparks.append(Spark(node: node, velocity: CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed),
                                life: life, total: life))
        }
    }

    func step(dt: CGFloat) {
        guard !sparks.isEmpty else { return }
        sparks = sparks.compactMap { spark in
            var spark = spark
            spark.life -= dt
            guard spark.life > 0 else {
                spark.node.removeFromParent()
                return nil
            }
            if spark.velocity != .zero { spark.velocity.dy -= Tuning.sparkGravity * dt }
            spark.node.position.x += spark.velocity.dx * dt
            spark.node.position.y += spark.velocity.dy * dt
            spark.node.alpha = spark.life / spark.total
            return spark
        }
    }
}
