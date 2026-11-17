import AppKit
import SpriteKit

/// L'albero di Natale: lo pianti dal menu, un clic su un ramo appende una pallina lì, si trascina come gli altri oggetti.
final class ChristmasTree: Toy {
    static let size = CGSize(width: 60, height: 84)
    /// Dove comincia e finisce la chioma (pt dai piedi) e quanto è larga in basso, per lato.
    nonisolated private static let foliage: ClosedRange<CGFloat> = 10...76
    nonisolated private static let halfWidth: CGFloat = 30
    /// I colori delle palline, a turno.
    private static let colors: [NSColor] = [.systemRed, .systemYellow, .systemBlue, .white, .systemPink]

    private(set) var baubles = 0

    init(at position: CGPoint) {
        let node = SKSpriteNode(texture: Self.texture)
        node.size = Self.size
        super.init(node: node, at: position)
    }

    /// Il punto (rispetto ai piedi) è sui rami? La chioma è un triangolo: largo in basso, a punta in alto.
    nonisolated static func isOnBranch(_ point: CGPoint) -> Bool {
        guard foliage.contains(point.y) else { return false }
        let reach = halfWidth * (1 - (point.y - foliage.lowerBound) / (foliage.upperBound - foliage.lowerBound))
        return abs(point.x) <= reach
    }

    override func clicked(at point: CGPoint) {
        guard Self.isOnBranch(point), baubles < Tuning.maxBaubles else { return }
        let bauble = SKSpriteNode(texture: Self.baubleTexture)
        bauble.size = CGSize(width: 7, height: 7)
        bauble.color = Self.colors[baubles % Self.colors.count]
        bauble.colorBlendFactor = 1
        bauble.position = point
        bauble.zPosition = 0.01
        node.addChild(bauble)
        baubles += 1
        SoundBoard.shared.play("pallina")
    }

    private static let baubleTexture = drawnTexture(size: CGSize(width: 7, height: 7)) { rect in
        NSColor.white.setFill()
        NSBezierPath(ovalIn: rect).fill()
    }

    private static let texture = drawnTexture(size: size) { rect in
        NSColor(calibratedRed: 0.45, green: 0.3, blue: 0.18, alpha: 1).setFill()
        NSBezierPath(rect: CGRect(x: rect.midX - 4, y: 0, width: 8, height: 12)).fill()
        // Tre palchi di rami, dal più largo in basso; insieme stanno dentro il triangolo di `isOnBranch`.
        let green = NSColor(calibratedRed: 0.13, green: 0.42, blue: 0.24, alpha: 1)
        for (bottom, half, top) in [(10.0, 30.0, 44.0), (30.0, 22.0, 62.0), (48.0, 14.0, 76.0)] {
            let tier = NSBezierPath()
            tier.move(to: CGPoint(x: rect.midX - half, y: bottom))
            tier.line(to: CGPoint(x: rect.midX + half, y: bottom))
            tier.line(to: CGPoint(x: rect.midX, y: top))
            tier.close()
            green.setFill()
            tier.fill()
        }
        // La stella in cima.
        let star = NSBezierPath()
        for i in 0..<10 {
            let angle = CGFloat(i) * .pi / 5 + .pi / 2
            let r: CGFloat = i % 2 == 0 ? 6 : 2.6
            let p = CGPoint(x: rect.midX + cos(angle) * r, y: 77 + sin(angle) * r)
            if i == 0 { star.move(to: p) } else { star.line(to: p) }
        }
        star.close()
        NSColor.systemYellow.setFill()
        star.fill()
    }
}
