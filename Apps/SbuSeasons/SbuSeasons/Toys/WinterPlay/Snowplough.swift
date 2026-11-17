import AppKit
import SpriteKit

/// Lo spazzaneve: va verso destra a velocità costante sul bordo su cui poggia e la lama raccoglie la neve posata.
/// Finito il bordo cade su quello sotto e continua, fino al fondo e fuori dallo schermo. La neve raccolta cresce
/// davanti alla lama; quando esce resta lì, una montagnetta (`Mound`). Lo manda `SeasonScene.sendPlough`.
final class Snowplough: Toy {
    static let size = CGSize(width: 36, height: 22)
    /// I granelli di neve raccolti (gli stessi di `Pile.scoop`).
    var load = 0 {
        didSet { heap.isHidden = load == 0; heap.setScale(min(1, 0.3 + CGFloat(load) / 300)) }
    }
    /// La neve davanti alla lama.
    private let heap = SKSpriteNode(texture: Mound.texture(size: CGSize(width: 24, height: 12)))

    init(at position: CGPoint) {
        let node = SKSpriteNode(texture: Self.texture)
        node.size = Self.size
        super.init(node: node, at: position)
        friction = 0
        heap.anchorPoint = CGPoint(x: 0, y: 0)
        heap.position = CGPoint(x: Self.size.width / 2 - 2, y: 0)
        heap.isHidden = true
        node.addChild(heap)
    }

    /// Il centro della neve che raccoglie, in coordinate della scena: tutta quella sotto il mezzo, fino alla lama
    /// (`Tuning.ploughBlade` per lato). Se no, all'inizio di ogni bordo resterebbe la neve sotto le ruote.
    var blade: CGPoint { CGPoint(x: body.position.x + 4, y: body.position.y + 1) }

    override func step(dt: CGFloat) {
        // Sul bordo va sempre avanti; in aria tiene lo slancio e cade.
        if body.isResting { body.velocity.dx = Tuning.ploughSpeed }
    }

    private static let texture = drawnTexture(size: size) { _ in
        let paint = NSColor.systemOrange
        let dark = NSColor(white: 0.15, alpha: 1)
        // La cabina col vetro, il corpo, la lama a destra, due ruote.
        paint.setFill()
        NSBezierPath(roundedRect: CGRect(x: 6, y: 11, width: 13, height: 10), xRadius: 2, yRadius: 2).fill()
        NSBezierPath(roundedRect: CGRect(x: 3, y: 5, width: 26, height: 8), xRadius: 2, yRadius: 2).fill()
        NSColor(calibratedRed: 0.75, green: 0.88, blue: 0.95, alpha: 1).setFill()
        NSBezierPath(rect: CGRect(x: 9, y: 13.5, width: 8, height: 5.5)).fill()
        NSColor(white: 0.55, alpha: 1).setFill()
        let blade = NSBezierPath()
        blade.move(to: CGPoint(x: 29, y: 4))
        blade.line(to: CGPoint(x: 36, y: 0))
        blade.line(to: CGPoint(x: 36, y: 14))
        blade.line(to: CGPoint(x: 29, y: 11))
        blade.close()
        blade.fill()
        dark.setFill()
        for x in [9.0, 23] { NSBezierPath(ovalIn: CGRect(x: x - 4, y: 0, width: 8, height: 8)).fill() }
    }
}
