import AppKit
import SpriteKit

/// La montagnetta che lascia lo spazzaneve: più neve ha raccolto, più è grande. Si sposta come gli altri oggetti.
final class Mound: Toy {
    /// `snow`: i granelli raccolti dallo spazzaneve.
    init(at position: CGPoint, snow: Int) {
        let width = min(70, 16 + CGFloat(snow) / 6)
        let size = CGSize(width: width.rounded(), height: (width * 0.45).rounded())
        let node = SKSpriteNode(texture: Self.texture(size: size))
        node.size = size
        super.init(node: node, at: position)
    }

    /// Una cupola di neve larga e bassa, con un po' d'ombra alla base.
    static func texture(size: CGSize) -> SKTexture {
        drawnTexture(size: size) { rect in
            let snow = Quaderno.paper.lightColor
            snow.setFill()
            NSBezierPath(ovalIn: CGRect(x: 0, y: -rect.height, width: rect.width, height: rect.height * 2)).fill()
            (snow.shadow(withLevel: 0.1) ?? snow).setFill()
            NSBezierPath(rect: CGRect(x: rect.width * 0.1, y: 0, width: rect.width * 0.8, height: 1.5)).fill()
        }
    }
}
