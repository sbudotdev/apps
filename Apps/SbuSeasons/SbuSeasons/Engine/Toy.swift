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
    /// false: un clic arriva, ma trascinandolo non si sposta (lo Yeti).
    var isDraggable = true
    /// false: può uscire di lato dallo schermo, e fuori dai bordi cammina sul prolungamento del fondo (i visitatori).
    var staysOnScreen = true

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

    /// Clic senza trascinare, nel punto `point` rispetto ai piedi (per un albero: su quale ramo).
    /// Di norma chiama `clicked()`.
    func clicked(at point: CGPoint) { clicked() }

    /// Il cursore o una finestra sono stati scossi.
    func shaken(_ shake: Shake) {}

    // MARK: Parti che si muovono da sole (le decorazioni dell'albero)

    /// Pressione nel punto `point` rispetto ai piedi. true = l'oggetto trascina una sua parte e il motore non lo sposta:
    /// poi arrivano `dragPart(to:)` e `releasePart(at:)`.
    func pressPart(at point: CGPoint) -> Bool { false }
    func dragPart(to point: CGPoint) {}
    func releasePart(at point: CGPoint) {}

    /// Pizzico sul trackpad o rotella sopra l'oggetto (`factor` > 1 = più grande), nel punto rispetto ai piedi.
    func resized(at point: CGPoint, by factor: CGFloat) {}
    /// Rotazione a due dita sul trackpad, o rotella con ⇧ o ⌥ (radianti, antiorario).
    func turned(at point: CGPoint, by radians: CGFloat) {}
}
