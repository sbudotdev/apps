import AppKit
import SpriteKit

/// Una frase al centro dello schermo, carta su inchiostro, quando la stagione non ha niente da far cadere
/// (Le tue immagini senza immagini, SBU-230). I clic la attraversano come il resto della scena.
final class Invitation: SKNode {
    private let label = SKLabelNode(fontNamed: NSFont.systemFont(ofSize: 15, weight: .medium).fontName)
    private var box = SKShapeNode()

    override init() {
        super.init()
        label.fontSize = 15
        label.fontColor = Quaderno.paper.lightColor
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.zPosition = 1
        addChild(box)
        addChild(label)
        zPosition = 50
        isHidden = true
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) non supportato") }

    /// `text` nil nasconde la frase. Sta al centro, un po' sopra la metà dello schermo.
    func show(_ text: String?, in size: CGSize) {
        isHidden = text == nil
        guard let text, text != label.text || box.frame.isEmpty else {
            position = CGPoint(x: size.width / 2, y: size.height * Tuning.invitationHeight)
            return
        }
        label.text = text
        box.removeFromParent()
        let frame = label.frame.insetBy(dx: -Quaderno.space4, dy: -Quaderno.space1 * 2)
        box = SKShapeNode(rect: frame, cornerRadius: Tuning.invitationRadius)
        box.fillColor = Quaderno.ink.lightColor.withAlphaComponent(Tuning.invitationOpacity)
        box.strokeColor = .clear
        insertChild(box, at: 0)
        position = CGPoint(x: size.width / 2, y: size.height * Tuning.invitationHeight)
    }

    var text: String? { isHidden ? nil : label.text }
}
