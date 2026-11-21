import AppKit
import SpriteKit

/// Lo Yeti (SBU-178): entra da un lato dello schermo, va dal pupazzo più vicino (se sta più in alto ci salta sopra),
/// se lo mette in spalla e se ne va. Un clic lo scaccia: lascia cadere il pupazzo e scappa. Non si trascina.
/// Lo muove `SeasonScene.stepVisitors`; quando passa lo decide `Visitors`.
final class Yeti: Toy {
    /// 1 = verso destra, -1 = verso sinistra.
    var heading: CGFloat
    /// Il pupazzo in spalla.
    var carried: Snowman?
    /// Scacciato: scappa e non prova più a prendere niente.
    private(set) var fleeing = false
    /// Gli hanno tolto il pupazzo di mano (trascinandolo via): se ne va a mani vuote.
    var gaveUp = false
    /// Colpito da una palla di neve: cade e sparisce (`isGone` dopo `Tuning.yetiFall` s).
    private(set) var knockedDown = false
    private var fallClock: CGFloat = 0
    var isGone: Bool { knockedDown && fallClock >= Tuning.yetiFall }
    private var gait: CGFloat = 0

    init(at position: CGPoint, heading: CGFloat) {
        self.heading = heading
        let node = SKSpriteNode(texture: Self.walking)
        node.size = Self.walking.size()
        super.init(node: node, at: position)
        friction = 0
        isDraggable = false
        staysOnScreen = false
    }

    /// Un clic: molla il pupazzo, che cade dov'è, e scappa verso il bordo più vicino.
    override func clicked() {
        guard !fleeing, let scene = node.scene as? SeasonScene else { return }
        fleeing = true
        carried?.body.release(velocity: .zero)
        carried = nil
        heading = body.position.x < scene.size.width / 2 ? -1 : 1
        SoundBoard.shared.play("yeti")
    }

    /// Una palla di neve lo colpisce: molla il pupazzo, cade all'indietro e sparisce.
    func knockDown() {
        guard !knockedDown else { return }
        knockedDown = true
        fleeing = true
        carried?.body.release(velocity: .zero)
        carried = nil
        body.velocity.dx = 0
        SoundBoard.shared.play("yeti")
    }

    override func step(dt: CGFloat) {
        let calm = (node.scene as? SeasonScene)?.reduceMotion ?? true
        if knockedDown {
            // Cade all'indietro in un attimo (con Riduci movimento no), poi svanisce.
            fallClock += dt
            node.zRotation = calm ? 0 : heading * min(1, fallClock / (Tuning.yetiFall * 0.25)) * .pi / 2
            node.alpha = 1 - min(1, max(0, (fallClock - Tuning.yetiFall * 0.5) / (Tuning.yetiFall * 0.5)))
            return
        }
        node.xScale = heading
        node.texture = carried == nil ? Self.walking : Self.carrying
        guard !calm, body.isResting, abs(body.velocity.dx) > 1 else { node.zRotation = 0; return }
        gait += dt * abs(body.velocity.dx) / 8
        node.zRotation = sin(gait) * 0.06
    }

    /// Dove portare il pupazzo in spalla: sopra la testa.
    var shoulders: CGPoint { CGPoint(x: body.position.x, y: body.position.y + node.size.height - 8) }

    // MARK: - Disegno

    private static let fur = NSColor(calibratedRed: 0.93, green: 0.94, blue: 0.97, alpha: 1)
    private static let skin = NSColor(calibratedRed: 0.55, green: 0.62, blue: 0.72, alpha: 1)

    private static func draw(armsUp: Bool) {
        let shade = fur.shadow(withLevel: 0.12) ?? fur
        fur.setFill()
        // Gambe, corpo, testa: grande e peloso, guarda a destra.
        for x in [9.0, 20] { NSBezierPath(roundedRect: CGRect(x: x, y: 0, width: 8, height: 12), xRadius: 3, yRadius: 3).fill() }
        NSBezierPath(ovalIn: CGRect(x: 4, y: 8, width: 28, height: 26)).fill()
        NSBezierPath(ovalIn: CGRect(x: 9, y: 27, width: 20, height: 17)).fill()
        // Le braccia: lungo i fianchi, o in alto a reggere il pupazzo.
        let arms = armsUp ? [CGRect(x: 4, y: 26, width: 6, height: 18), CGRect(x: 26, y: 26, width: 6, height: 18)]
                          : [CGRect(x: 1, y: 10, width: 7, height: 18), CGRect(x: 28, y: 10, width: 7, height: 18)]
        for arm in arms { NSBezierPath(roundedRect: arm, xRadius: 3, yRadius: 3).fill() }
        shade.setFill()
        NSBezierPath(ovalIn: CGRect(x: 10, y: 10, width: 16, height: 4)).fill()
        // La faccia azzurrina, gli occhi e la bocca.
        skin.setFill()
        NSBezierPath(ovalIn: CGRect(x: 15, y: 29, width: 12, height: 10)).fill()
        NSColor(white: 0.12, alpha: 1).setFill()
        for x in [18.5, 23] { NSBezierPath(ovalIn: CGRect(x: x, y: 35, width: 2, height: 2)).fill() }
        NSBezierPath(roundedRect: CGRect(x: 19, y: 31, width: 5, height: 1.6), xRadius: 0.8, yRadius: 0.8).fill()
    }

    private static let walking = drawnTexture(size: CGSize(width: 36, height: 45)) { _ in draw(armsUp: false) }
    private static let carrying = drawnTexture(size: CGSize(width: 36, height: 45)) { _ in draw(armsUp: true) }
}
