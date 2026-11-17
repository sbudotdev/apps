import SpriteKit

/// Un oggetto con cui giocare (palla di neve, slittino, personaggio…): sta in piedi sui bordi delle finestre
/// e del Dock, cade, si clicca e si trascina. Il motore lo muove; un oggetto vero sovrascrive `clicked()`
/// e `shaken(_:)` e disegna il suo `node`. Come se ne aggiunge uno: README, "Aggiungere un oggetto".
class Toy {
    /// Il disegno. L'àncora è il centro in basso: `position` è dove poggiano i piedi.
    let node: SKSpriteNode
    var body: ToyBody
    /// Quanto rimbalza quando cade su un bordo (0 = per niente). Con Riduci movimento non rimbalza mai.
    var bounce: CGFloat = 0
    /// Quanto in fretta si ferma quando poggia su un bordo (più basso = scivola o rotola più lontano).
    var friction: CGFloat = Tuning.toyFriction

    init(node: SKSpriteNode, at position: CGPoint) {
        self.node = node
        body = ToyBody(position: position)
        node.anchorPoint = CGPoint(x: 0.5, y: 0)
        node.position = position
        node.zPosition = 2   // davanti ai fiocchi e alla polvere
    }

    /// Dove si clicca, in coordinate della scena.
    var frame: CGRect {
        CGRect(x: body.position.x - node.size.width / 2, y: body.position.y,
               width: node.size.width, height: node.size.height)
    }

    /// Dopo ogni passo del motore: per animare il disegno (una palla che gira mentre rotola).
    func step(dt: CGFloat) {}

    /// Clic senza trascinare.
    func clicked() {}

    /// Il cursore o una finestra sono stati scossi.
    func shaken(_ shake: Shake) {}
}
