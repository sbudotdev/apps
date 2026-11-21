import AppKit
import SpriteKit

/// L'albero di Natale da decorare (SBU-178). Lo pianti dal menu (fino a 3); un clic sui rami appende la decorazione
/// scelta nella sua scheda (palline, luci, bastoncini di zucchero, la stella in cima). Le decorazioni si trascinano
/// (fuori dall'albero si tolgono), si ingrandiscono col pizzico o la rotella e si girano con due dita o ⇧ e la rotella.
/// Pizzico o rotella sull'albero lo fanno crescere. Si trascina come gli altri oggetti; dalla scheda si taglia.
/// Com'è fatto sta tutto in `look`, che si salva (`KeptToys`).
final class ChristmasTree: Toy {
    static let size = CGSize(width: 60, height: 84)
    /// I colori delle palline, a turno (`Decoration.color`).
    static let colors: [NSColor] = [.systemRed, .systemYellow, .systemBlue, .white, .systemPink]

    /// L'albero a grandezza 1, con le decorazioni dentro: crescendo si scala tutto insieme.
    private let crown = SKSpriteNode(texture: ChristmasTree.texture)
    private var dragged: Int?
    /// La decorazione su cui si è aperta la scheda (clic destro), se c'era: la scheda mostra anche lei.
    var cardFocus: Int?
    private var twinkle: CGFloat = 0

    var look: TreeLook {
        didSet { if look != oldValue { redraw(growing: look.growth != oldValue.growth) } }
    }

    init(at position: CGPoint, look: TreeLook = TreeLook()) {
        self.look = look
        super.init(node: SKSpriteNode(color: .clear, size: Self.size), at: position)
        crown.size = Self.size
        crown.anchorPoint = CGPoint(x: 0.5, y: 0)
        node.addChild(crown)
        redraw(growing: true)
    }

    /// Dal punto rispetto ai piedi (punti della scena) alle coordinate dell'albero a grandezza 1.
    private func local(_ point: CGPoint) -> CGPoint { CGPoint(x: point.x / look.growth, y: point.y / look.growth) }

    private func redraw(growing: Bool) {
        if growing {
            node.size = CGSize(width: Self.size.width * look.growth, height: Self.size.height * look.growth)
            crown.setScale(look.growth)
        }
        crown.removeAllChildren()
        for (i, decoration) in look.decorations.enumerated() {
            let sprite = SKSpriteNode(texture: Self.texture(decoration.kind))
            let side = decoration.kind.side
            sprite.size = decoration.kind == .lights ? CGSize(width: side, height: side / 2) : CGSize(width: side, height: side)
            sprite.setScale(decoration.scale)
            sprite.zRotation = decoration.rotation
            sprite.position = decoration.position
            sprite.zPosition = 0.01 + CGFloat(i) * 0.0001
            if decoration.kind == .bauble {
                sprite.color = Self.colors[decoration.color % Self.colors.count]
                sprite.colorBlendFactor = 1
            }
            sprite.name = decoration.kind.rawValue
            crown.addChild(sprite)
        }
    }

    // MARK: - Gesti

    override func clicked(at point: CGPoint) {
        guard look.hang(at: local(point)) else { return }
        SoundBoard.shared.play("pallina")
    }

    override func pressPart(at point: CGPoint) -> Bool {
        dragged = look.decoration(at: local(point))
        return dragged != nil
    }

    override func dragPart(to point: CGPoint) {
        if let dragged { look.move(dragged, to: local(point)) }
    }

    override func releasePart(at point: CGPoint) {
        guard let index = dragged else { return }
        dragged = nil
        look.drop(index, at: local(point))
    }

    /// Sopra una decorazione la ridimensiona, se no fa crescere (o abbassare) l'albero.
    override func resized(at point: CGPoint, by factor: CGFloat) {
        if let index = look.decoration(at: local(point)) {
            look.resize(index, by: factor)
        } else {
            look.grow(by: factor)
        }
    }

    override func turned(at point: CGPoint, by radians: CGFloat) {
        if let index = look.decoration(at: local(point)) { look.turn(index, by: radians) }
    }

    /// "Taglia l'albero" nella scheda.
    func cut() {
        guard let scene = node.scene as? SeasonScene else { return }
        scene.sparkle(at: CGPoint(x: body.position.x, y: body.position.y + 20))
        scene.remove(self)
    }

    /// Le luci si accendono e si spengono piano, a turno; con Riduci movimento restano accese.
    override func step(dt: CGFloat) {
        let calm = (node.scene as? SeasonScene)?.reduceMotion ?? true
        twinkle += dt
        for (i, sprite) in crown.children.enumerated() where sprite.name == DecorationKind.lights.rawValue {
            sprite.alpha = calm ? 1 : 0.7 + 0.3 * sin(twinkle * 3 + CGFloat(i))
        }
    }

    // MARK: - Disegni

    static func texture(_ kind: DecorationKind) -> SKTexture {
        switch kind {
        case .bauble: baubleTexture
        case .lights: lightsTexture
        case .candyCane: candyCaneTexture
        case .star: starTexture
        }
    }

    private static let baubleTexture = drawnTexture(size: CGSize(width: 7, height: 7)) { rect in
        NSColor.white.setFill()
        NSBezierPath(ovalIn: rect).fill()
    }

    /// Un filo di luci: il cavo che pende e cinque lampadine colorate.
    private static let lightsTexture = drawnTexture(size: CGSize(width: 22, height: 11)) { _ in
        let wire = NSBezierPath()
        wire.move(to: CGPoint(x: 1, y: 8))
        wire.curve(to: CGPoint(x: 21, y: 8), controlPoint1: CGPoint(x: 7, y: 1), controlPoint2: CGPoint(x: 15, y: 1))
        wire.lineWidth = 0.8
        NSColor(calibratedRed: 0.1, green: 0.25, blue: 0.12, alpha: 1).setStroke()
        wire.stroke()
        let bulbs: [(CGFloat, CGFloat, NSColor)] = [(2, 6.5, .systemRed), (6.5, 3.5, .systemYellow), (11, 2.5, .systemTeal),
                                                     (15.5, 3.5, .systemOrange), (20, 6.5, .systemPink)]
        for (x, y, color) in bulbs {
            color.setFill()
            NSBezierPath(ovalIn: CGRect(x: x - 1.6, y: y - 2.2, width: 3.2, height: 3.2)).fill()
        }
    }

    /// Il bastoncino di zucchero: un uncino bianco a strisce rosse.
    private static let candyCaneTexture = drawnTexture(size: CGSize(width: 10, height: 10)) { _ in
        let cane = NSBezierPath()
        cane.move(to: CGPoint(x: 4, y: 0.5))
        cane.line(to: CGPoint(x: 4, y: 7))
        cane.appendArc(withCenter: CGPoint(x: 6, y: 7), radius: 2, startAngle: 180, endAngle: 0, clockwise: true)
        cane.line(to: CGPoint(x: 8, y: 6))
        cane.lineWidth = 2
        cane.lineCapStyle = .round
        NSColor.white.setStroke()
        cane.stroke()
        cane.lineWidth = 2
        cane.setLineDash([1.2, 1.4], count: 2, phase: 0)
        NSColor.systemRed.setStroke()
        cane.stroke()
    }

    private static let starTexture = drawnTexture(size: CGSize(width: 13, height: 13)) { rect in
        let star = NSBezierPath()
        for i in 0..<10 {
            let angle = CGFloat(i) * .pi / 5 + .pi / 2
            let r: CGFloat = i % 2 == 0 ? 6.3 : 2.7
            let p = CGPoint(x: rect.midX + cos(angle) * r, y: rect.midY + sin(angle) * r)
            if i == 0 { star.move(to: p) } else { star.line(to: p) }
        }
        star.close()
        NSColor.systemYellow.setFill()
        star.fill()
    }

    private static let texture = drawnTexture(size: size) { rect in
        NSColor(calibratedRed: 0.45, green: 0.3, blue: 0.18, alpha: 1).setFill()
        NSBezierPath(rect: CGRect(x: rect.midX - 4, y: 0, width: 8, height: 12)).fill()
        // Tre palchi di rami, dal più largo in basso; insieme stanno dentro il triangolo di `TreeLook.isOnBranch`.
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
    }
}
