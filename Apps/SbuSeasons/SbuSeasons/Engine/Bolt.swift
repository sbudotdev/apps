import AppKit
import SpriteKit

/// Il fulmine sull'icona del Dock di un'app che chiudi mentre piove (SBU-185): una linea spezzata dalla cima dello
/// schermo all'icona, che si spegne in `Tuning.boltLife` s. Serve il permesso Accessibilità (già chiesto per il Dock)
/// per sapere dov'è l'icona; con Riduci movimento non c'è, perché è luce che lampeggia. Nessun dato esce dal Mac.
final class Bolt: SKShapeNode {
    /// Solo quando piove (la stagione ha i lampi), con l'Accessibilità e senza Riduci movimento.
    static func strikes(season: any Season, reduceMotion: Bool, trusted: Bool) -> Bool {
        season.lightning != nil && !reduceMotion && trusted
    }

    /// I punti della linea: parte da `top` poco di lato rispetto all'icona, scende sempre e finisce su `target`.
    static func points(from top: CGFloat, to target: CGPoint, segments: Int) -> [CGPoint] {
        let startX = target.x + .random(in: -60...60)
        return (0...segments).map { i in
            let f = CGFloat(i) / CGFloat(segments)
            let jitter: CGFloat = i == 0 || i == segments ? 0 : .random(in: -32...32)
            return CGPoint(x: startX + (target.x - startX) * f + jitter, y: top + (target.y - top) * f)
        }
    }

    private var life = Tuning.boltLife

    init(from top: CGFloat, to target: CGPoint) {
        super.init()
        let path = CGMutablePath()
        path.addLines(between: Self.points(from: top, to: target, segments: Tuning.boltSegments))
        self.path = path
        // Un azzurro elettrico, non bianco: sugli sfondi chiari il bianco spariva.
        strokeColor = NSColor(srgbRed: 0.55, green: 0.7, blue: 1, alpha: 1)
        lineWidth = 3
        glowWidth = 6
        lineJoin = .miter
        zPosition = 1.8   // davanti alle gocce sul vetro, dietro ai mucchi
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) non supportato") }

    /// Un passo: sfuma; false = finito (chi lo ha aggiunto lo toglie).
    func step(dt: CGFloat) -> Bool {
        life -= dt
        alpha = max(0, life / Tuning.boltLife)
        return life > 0
    }
}
