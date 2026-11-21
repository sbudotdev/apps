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
        breaks = true
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
        if look.cape {
            // Dietro il pupazzo: scende dal collo fino a terra, più largo in basso.
            let neck = balls[2].minY + 1
            let cape = NSBezierPath()
            cape.move(to: CGPoint(x: balls[2].midX - balls[2].width * 0.45, y: neck))
            cape.line(to: CGPoint(x: balls[2].midX + balls[2].width * 0.45, y: neck))
            // Esce ai lati della pancia, se no non si vedrebbe.
            cape.line(to: CGPoint(x: balls[0].maxX + 3, y: 1))
            cape.line(to: CGPoint(x: balls[0].minX - 3, y: 1))
            cape.close()
            NSColor(calibratedRed: 0.55, green: 0.1, blue: 0.14, alpha: 1).setFill()
            cape.fill()
        }
        if look.mittens {
            // Due rametti dal petto, con una muffola rossa in fondo.
            let chest = balls[1]
            let brown = NSColor(calibratedRed: 0.42, green: 0.28, blue: 0.16, alpha: 1)
            for side in [-1.0, 1.0] {
                let start = CGPoint(x: chest.midX + side * chest.width * 0.4, y: chest.midY)
                let end = CGPoint(x: chest.midX + side * (chest.width / 2 + 8), y: chest.midY + 5)
                let arm = NSBezierPath()
                arm.move(to: start)
                arm.line(to: end)
                arm.lineWidth = 1.2
                brown.setStroke()
                arm.stroke()
                NSColor(calibratedRed: 0.78, green: 0.12, blue: 0.16, alpha: 1).setFill()
                NSBezierPath(ovalIn: CGRect(x: end.x - 2.5, y: end.y - 1, width: 5, height: 5)).fill()
                NSBezierPath(ovalIn: CGRect(x: end.x - side * 3.2 - 1, y: end.y + 1, width: 2.2, height: 2.6)).fill()
            }
        }
        for ball in balls {
            snow.setFill()
            NSBezierPath(ovalIn: ball).fill()
            shade.setFill()
            NSBezierPath(ovalIn: CGRect(x: ball.midX - ball.width * 0.3, y: ball.minY + 0.5, width: ball.width * 0.6, height: 3)).fill()
        }
        let chest = balls[1]
        let head = balls[2]
        if look.sweater {
            // Il maglione copre il petto: rosso, con una riga bianca a puntini.
            NSGraphicsContext.saveGraphicsState()
            NSBezierPath(ovalIn: chest).addClip()
            NSColor(calibratedRed: 0.72, green: 0.13, blue: 0.16, alpha: 1).setFill()
            chest.fill()
            NSColor.white.setFill()
            for x in stride(from: chest.minX + 2, to: chest.maxX, by: 4) {
                NSBezierPath(ovalIn: CGRect(x: x - 1, y: chest.midY - 1, width: 2, height: 2)).fill()
            }
            NSGraphicsContext.restoreGraphicsState()
        }
        coal.setFill()
        if look.buttons {
            for y in [chest.midY - chest.height * 0.15, chest.midY + chest.height * 0.15] {
                NSBezierPath(ovalIn: CGRect(x: chest.midX - 1, y: y - 1, width: 2, height: 2)).fill()
            }
        }
        let eyes = head.minY + head.height * 0.6
        for dx in [-head.width * 0.18, head.width * 0.18] {
            switch look.eyes {
            case .coal:
                NSBezierPath(ovalIn: CGRect(x: head.midX + dx - 1, y: eyes - 1, width: 2, height: 2)).fill()
            case .stars:
                NSColor.systemYellow.setFill()
                star(at: CGPoint(x: head.midX + dx, y: eyes), radius: 2.2).fill()
                coal.setFill()
            }
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
            if look.scarf == .striped {
                NSColor.white.setFill()
                for x in stride(from: head.midX - head.width * 0.45, to: head.midX + head.width * 0.55, by: 3) {
                    NSBezierPath(rect: CGRect(x: x, y: neck - 1.5, width: 1, height: 3.5)).fill()
                }
                for y in [neck - 3, neck - 6] {
                    NSBezierPath(rect: CGRect(x: head.midX - head.width * 0.4, y: y, width: 3, height: 1)).fill()
                }
            }
        }
        if look.bowTie {
            // Il papillon sotto la testa: due triangoli neri e un nodo.
            let knot = CGPoint(x: head.midX, y: head.minY - 0.5)
            NSColor(white: 0.1, alpha: 1).setFill()
            for side in [-1.0, 1.0] {
                let wing = NSBezierPath()
                wing.move(to: knot)
                wing.line(to: CGPoint(x: knot.x + side * 4.5, y: knot.y + 2.2))
                wing.line(to: CGPoint(x: knot.x + side * 4.5, y: knot.y - 2.2))
                wing.close()
                wing.fill()
            }
            NSBezierPath(ovalIn: CGRect(x: knot.x - 1.2, y: knot.y - 1.2, width: 2.4, height: 2.4)).fill()
        }
        let crown = head.maxY - 1.5
        drawHat(look.hat, on: head, at: crown)
    }

    private static func drawHat(_ hat: SnowmanLook.Hat, on head: CGRect, at crown: CGFloat) {
        switch hat {
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
        case .cowboy:
            // Falda larga e incurvata, cupola marrone con un nastro.
            let brown = NSColor(calibratedRed: 0.55, green: 0.36, blue: 0.2, alpha: 1)
            brown.setFill()
            NSBezierPath(roundedRect: CGRect(x: head.midX - head.width * 0.8, y: crown, width: head.width * 1.6, height: 2),
                         xRadius: 1, yRadius: 1).fill()
            NSBezierPath(roundedRect: CGRect(x: head.midX - head.width * 0.35, y: crown + 1.5, width: head.width * 0.7, height: 6),
                         xRadius: 2.5, yRadius: 2.5).fill()
            NSColor(white: 0.15, alpha: 1).setFill()
            NSBezierPath(rect: CGRect(x: head.midX - head.width * 0.35, y: crown + 2, width: head.width * 0.7, height: 1.2)).fill()
        case .party:
            // Un cono a righe con il pompon.
            let cone = NSBezierPath()
            cone.move(to: CGPoint(x: head.midX - head.width * 0.3, y: crown))
            cone.line(to: CGPoint(x: head.midX + head.width * 0.3, y: crown))
            cone.line(to: CGPoint(x: head.midX, y: crown + 11))
            cone.close()
            NSColor.systemTeal.setFill()
            cone.fill()
            NSGraphicsContext.saveGraphicsState()
            cone.addClip()
            NSColor.systemPink.setFill()
            for y in stride(from: crown + 2, to: crown + 11, by: 4) {
                NSBezierPath(rect: CGRect(x: head.midX - head.width * 0.4, y: y, width: head.width * 0.8, height: 1.5)).fill()
            }
            NSGraphicsContext.restoreGraphicsState()
            NSColor.systemYellow.setFill()
            NSBezierPath(ovalIn: CGRect(x: head.midX - 1.5, y: crown + 10, width: 3, height: 3)).fill()
        case .elf:
            // Verde, lungo e piegato di lato, con il bordo rosso e il campanellino.
            let green = NSColor(calibratedRed: 0.13, green: 0.5, blue: 0.28, alpha: 1)
            let cap = NSBezierPath()
            cap.move(to: CGPoint(x: head.midX - head.width * 0.45, y: crown))
            cap.line(to: CGPoint(x: head.midX + head.width * 0.45, y: crown))
            cap.curve(to: CGPoint(x: head.midX + head.width * 0.75, y: crown + 9),
                      controlPoint1: CGPoint(x: head.midX + head.width * 0.3, y: crown + 8),
                      controlPoint2: CGPoint(x: head.midX + head.width * 0.5, y: crown + 12))
            cap.curve(to: CGPoint(x: head.midX - head.width * 0.45, y: crown),
                      controlPoint1: CGPoint(x: head.midX, y: crown + 14),
                      controlPoint2: CGPoint(x: head.midX - head.width * 0.4, y: crown + 6))
            green.setFill()
            cap.fill()
            NSColor.systemRed.setFill()
            NSBezierPath(rect: CGRect(x: head.midX - head.width * 0.47, y: crown - 1, width: head.width * 0.94, height: 2)).fill()
            NSColor.systemYellow.setFill()
            NSBezierPath(ovalIn: CGRect(x: head.midX + head.width * 0.75 - 1.5, y: crown + 7.5, width: 3, height: 3)).fill()
        case .pirate:
            // Il tricorno nero con il teschietto bianco (un puntino).
            let hat = NSBezierPath()
            hat.move(to: CGPoint(x: head.midX - head.width * 0.7, y: crown))
            hat.curve(to: CGPoint(x: head.midX + head.width * 0.7, y: crown),
                      controlPoint1: CGPoint(x: head.midX - head.width * 0.3, y: crown + 11),
                      controlPoint2: CGPoint(x: head.midX + head.width * 0.3, y: crown + 11))
            hat.close()
            coal.setFill()
            hat.fill()
            NSColor.white.setFill()
            NSBezierPath(ovalIn: CGRect(x: head.midX - 1.5, y: crown + 3, width: 3, height: 3)).fill()
        case .crown:
            // Una corona d'oro a tre punte, con una gemma rossa.
            let gold = NSBezierPath()
            let left = head.midX - head.width * 0.38
            let width = head.width * 0.76
            gold.move(to: CGPoint(x: left, y: crown))
            gold.line(to: CGPoint(x: left + width, y: crown))
            gold.line(to: CGPoint(x: left + width, y: crown + 7))
            gold.line(to: CGPoint(x: left + width * 0.75, y: crown + 4))
            gold.line(to: CGPoint(x: left + width * 0.5, y: crown + 7.5))
            gold.line(to: CGPoint(x: left + width * 0.25, y: crown + 4))
            gold.line(to: CGPoint(x: left, y: crown + 7))
            gold.close()
            NSColor.systemYellow.setFill()
            gold.fill()
            NSColor.systemRed.setFill()
            NSBezierPath(ovalIn: CGRect(x: head.midX - 1, y: crown + 1.2, width: 2, height: 2)).fill()
        case .antlers:
            // Due corna di renna marroni, a forchetta.
            let antler = NSBezierPath()
            for side in [-1.0, 1.0] {
                let base = CGPoint(x: head.midX + side * head.width * 0.25, y: crown)
                let top = CGPoint(x: base.x + side * 4, y: crown + 9.5)
                antler.move(to: base)
                antler.line(to: top)
                antler.move(to: CGPoint(x: base.x + side * 1.6, y: crown + 4))
                antler.line(to: CGPoint(x: base.x + side * 5.5, y: crown + 5.5))
                antler.move(to: CGPoint(x: base.x + side * 3, y: crown + 7))
                antler.line(to: CGPoint(x: base.x + side * 0.5, y: crown + 9.5))
            }
            antler.lineWidth = 1.5
            antler.lineCapStyle = .round
            NSColor(calibratedRed: 0.5, green: 0.32, blue: 0.18, alpha: 1).setStroke()
            antler.stroke()
        case .none:
            break
        }
    }

    /// Una stella a cinque punte.
    static func star(at center: CGPoint, radius: CGFloat) -> NSBezierPath {
        let star = NSBezierPath()
        for i in 0..<10 {
            let angle = CGFloat(i) * .pi / 5 + .pi / 2
            let r = i % 2 == 0 ? radius : radius * 0.43
            let p = CGPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r)
            if i == 0 { star.move(to: p) } else { star.line(to: p) }
        }
        star.close()
        return star
    }

    private static func scarfColor(_ scarf: SnowmanLook.Scarf) -> NSColor? {
        switch scarf {
        case .none: nil
        case .red: NSColor(calibratedRed: 0.78, green: 0.12, blue: 0.16, alpha: 1)
        case .green: NSColor(calibratedRed: 0.13, green: 0.5, blue: 0.28, alpha: 1)
        case .striped: NSColor(calibratedRed: 0.13, green: 0.32, blue: 0.62, alpha: 1)
        }
    }
}
