import AppKit
import SpriteKit

/// Il trenino con l'elfo (SBU-178): corre sul fondo dello schermo e, se lo porta, lascia un regalo in `dropX`
/// (dentro c'è un oggetto nuovo per l'albero o il pupazzo, `ElfPresent`). Come la slitta, non si prende:
/// i clic passano sotto. Lo muove `SeasonScene.stepVisitors`; quando passa lo decide `Visitors`.
final class Train {
    let node = SKSpriteNode(texture: Train.texture)
    /// 1 = verso destra, -1 = verso sinistra.
    let heading: CGFloat
    /// Dove lascia il regalo (x della scena). nil = già lasciato, o non lo porta.
    var dropX: CGFloat?

    init(heading: CGFloat) {
        self.heading = heading
        node.size = Train.texture.size()
        node.anchorPoint = CGPoint(x: 0.5, y: 0)
        node.xScale = heading
        node.zPosition = 1.9   // davanti ai fiocchi, dietro gli oggetti
    }

    private static let texture = drawnTexture(size: CGSize(width: 104, height: 34)) { _ in
        let red = NSColor(calibratedRed: 0.78, green: 0.12, blue: 0.16, alpha: 1)
        let green = NSColor(calibratedRed: 0.13, green: 0.45, blue: 0.26, alpha: 1)
        let gold = NSColor(calibratedRed: 0.98, green: 0.78, blue: 0.2, alpha: 1)
        let iron = NSColor(white: 0.18, alpha: 1)
        // Il gancio tra i vagoni.
        iron.setFill()
        NSBezierPath(rect: CGRect(x: 4, y: 6, width: 70, height: 2)).fill()
        // Il vagone dietro, con i regali.
        green.setFill()
        NSBezierPath(roundedRect: CGRect(x: 2, y: 5, width: 30, height: 12), xRadius: 2, yRadius: 2).fill()
        for (x, color) in [(5.0, red), (17.0, gold)] {
            color.setFill()
            NSBezierPath(rect: CGRect(x: x, y: 17, width: 9, height: 8)).fill()
        }
        // Il vagone con l'elfo: cappello a punta verde col pon pon, faccia, saluta con la mano.
        red.setFill()
        NSBezierPath(roundedRect: CGRect(x: 36, y: 5, width: 26, height: 12), xRadius: 2, yRadius: 2).fill()
        green.setFill()
        NSBezierPath(rect: CGRect(x: 44, y: 16, width: 10, height: 7)).fill()
        NSColor(calibratedRed: 0.98, green: 0.82, blue: 0.7, alpha: 1).setFill()
        NSBezierPath(ovalIn: CGRect(x: 45, y: 22, width: 8, height: 7)).fill()
        NSBezierPath(ovalIn: CGRect(x: 55, y: 24, width: 3, height: 3)).fill()   // la mano che saluta
        green.setFill()
        let hat = NSBezierPath()
        hat.move(to: CGPoint(x: 44.5, y: 27.5)); hat.line(to: CGPoint(x: 53.5, y: 27.5)); hat.line(to: CGPoint(x: 43, y: 33.5)); hat.close()
        hat.fill()
        NSColor.white.setFill()
        NSBezierPath(ovalIn: CGRect(x: 41, y: 31.5, width: 3, height: 3)).fill()
        // La locomotiva: caldaia, cabina, comignolo, il fanale d'oro davanti.
        red.setFill()
        NSBezierPath(roundedRect: CGRect(x: 66, y: 5, width: 30, height: 11), xRadius: 4, yRadius: 4).fill()
        NSBezierPath(rect: CGRect(x: 66, y: 5, width: 12, height: 20)).fill()
        iron.setFill()
        NSBezierPath(rect: CGRect(x: 64, y: 24, width: 16, height: 2.5)).fill()
        NSBezierPath(rect: CGRect(x: 86, y: 15, width: 5, height: 9)).fill()
        gold.setFill()
        NSBezierPath(ovalIn: CGRect(x: 95, y: 9, width: 5, height: 5)).fill()
        NSBezierPath(rect: CGRect(x: 66, y: 14, width: 30, height: 1.5)).fill()
        // Le ruote.
        iron.setFill()
        for x in [6.0, 22, 40, 54, 70, 86] { NSBezierPath(ovalIn: CGRect(x: x, y: 0, width: 7, height: 7)).fill() }
    }
}
