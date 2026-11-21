import AppKit
import SpriteKit

/// Il pupazzo di neve: nasce da tre palle vicine. Un clic (o il clic destro) apre la sua scheda (`SnowmanCard`):
/// la taglia delle tre palle e i vestiti (SBU-178). Si sposta e si lancia come gli altri oggetti.
final class Snowman: Toy {
    var look: SnowmanLook {
        didSet {
            guard look != oldValue else { return }
            node.texture = Self.texture(look)
            node.size = look.size
        }
    }

    init(at position: CGPoint, look: SnowmanLook = SnowmanLook()) {
        self.look = look
        let node = SKSpriteNode(texture: Self.texture(look))
        node.size = look.size
        super.init(node: node, at: position)
    }

    override func clicked() {
        (node.scene as? SeasonScene)?.openCard(for: self, at: CGPoint(x: body.position.x, y: body.position.y + node.size.height))
    }

    // MARK: - Disegno

    /// Un disegno per ogni aspetto, fatto la prima volta che serve.
    private static var textures: [SnowmanLook: SKTexture] = [:]

    static func texture(_ look: SnowmanLook) -> SKTexture {
        if let texture = textures[look] { return texture }
        let texture = drawnTexture(size: look.size) { _ in draw(look) }
        textures[look] = texture
        return texture
    }

    private static let coal = NSColor(white: 0.15, alpha: 1)

    private static func draw(_ look: SnowmanLook) {
        let snow = Quaderno.paper.lightColor
        let shade = snow.shadow(withLevel: 0.12) ?? snow
        let balls = look.ballFrames
        for ball in balls {
            snow.setFill()
            NSBezierPath(ovalIn: ball).fill()
            shade.setFill()
            NSBezierPath(ovalIn: CGRect(x: ball.midX - ball.width * 0.3, y: ball.minY + 0.5, width: ball.width * 0.6, height: 3)).fill()
        }
        let chest = balls[1]
        let head = balls[2]
        coal.setFill()
        if look.buttons {
            for y in [chest.midY - chest.height * 0.15, chest.midY + chest.height * 0.15] {
                NSBezierPath(ovalIn: CGRect(x: chest.midX - 1, y: y - 1, width: 2, height: 2)).fill()
            }
        }
        let eyes = head.minY + head.height * 0.6
        for dx in [-head.width * 0.18, head.width * 0.18] {
            NSBezierPath(ovalIn: CGRect(x: head.midX + dx - 1, y: eyes - 1, width: 2, height: 2)).fill()
        }
        let noseY = head.minY + head.height * 0.42
        switch look.nose {
        case .carrot:
            // Una carota che guarda a destra.
            let nose = NSBezierPath()
            nose.move(to: CGPoint(x: head.midX, y: noseY + 1))
            nose.line(to: CGPoint(x: head.midX + head.width * 0.5, y: noseY))
            nose.line(to: CGPoint(x: head.midX, y: noseY - 1))
            nose.close()
            NSColor.systemOrange.setFill()
            nose.fill()
        case .coal:
            NSBezierPath(ovalIn: CGRect(x: head.midX - 1.5, y: noseY - 1.5, width: 3, height: 3)).fill()
        case .none:
            break
        }
        if let color = scarfColor(look.scarf) {
            color.setFill()
            // Al collo, dove la testa entra nel petto, e un lembo che pende a sinistra.
            let neck = head.minY + 1
            NSBezierPath(roundedRect: CGRect(x: head.midX - head.width * 0.55, y: neck - 1.5, width: head.width * 1.1, height: 3.5),
                         xRadius: 1.5, yRadius: 1.5).fill()
            NSBezierPath(roundedRect: CGRect(x: head.midX - head.width * 0.4, y: neck - 8, width: 3, height: 8),
                         xRadius: 1, yRadius: 1).fill()
        }
        let crown = head.maxY - 1.5
        switch look.hat {
        case .topHat:
            coal.setFill()
            NSBezierPath(rect: CGRect(x: head.midX - head.width * 0.6, y: crown, width: head.width * 1.2, height: 2)).fill()
            NSBezierPath(rect: CGRect(x: head.midX - head.width * 0.38, y: crown + 2, width: head.width * 0.76, height: 9)).fill()
            NSColor.systemRed.setFill()
            NSBezierPath(rect: CGRect(x: head.midX - head.width * 0.38, y: crown + 3, width: head.width * 0.76, height: 1.5)).fill()
        case .beanie:
            NSColor.systemRed.setFill()
            NSBezierPath(roundedRect: CGRect(x: head.midX - head.width * 0.45, y: crown - 1, width: head.width * 0.9, height: 6),
                         xRadius: 3, yRadius: 3).fill()
            NSColor.white.setFill()
            NSBezierPath(rect: CGRect(x: head.midX - head.width * 0.47, y: crown - 1.5, width: head.width * 0.94, height: 2)).fill()
            NSBezierPath(ovalIn: CGRect(x: head.midX - 2, y: crown + 4.5, width: 4, height: 4)).fill()
        case .none:
            break
        }
    }

    private static func scarfColor(_ scarf: SnowmanLook.Scarf) -> NSColor? {
        switch scarf {
        case .none: nil
        case .red: NSColor(calibratedRed: 0.78, green: 0.12, blue: 0.16, alpha: 1)
        case .green: NSColor(calibratedRed: 0.13, green: 0.5, blue: 0.28, alpha: 1)
        }
    }
}
