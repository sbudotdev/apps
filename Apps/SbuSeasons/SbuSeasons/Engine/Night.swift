import AppKit
import SpriteKit

/// La notte (Impostazioni → Notte): spenta, dall'ora scelta fino al mattino, o sempre.
nonisolated enum NightMode: String, Codable, CaseIterable, Sendable {
    case off, late, always
}

nonisolated enum NightClock {
    /// È notte all'ora `hour` (0…23)? Con `late` dalle `startHour` fino alle `Tuning.nightEnds` del mattino.
    static func isNight(mode: NightMode, startHour: Int, hour: Int) -> Bool {
        switch mode {
        case .off: false
        case .always: true
        case .late: startHour >= Tuning.nightEnds
            ? hour >= startHour || hour < Tuning.nightEnds
            : hour >= startHour && hour < Tuning.nightEnds
        }
    }
}

/// Di notte lo schermo si scurisce un po' e in basso a destra c'è una candela, con l'alone intorno alla fiamma
/// e una luce calda sul fondo. Tre sprite in tutto; la fiamma tremola (con Riduci movimento no).
final class Night: SKNode {
    private(set) var isOn = false
    private let dim = SKSpriteNode(color: .black, size: .zero)
    private let candle = SKSpriteNode(texture: Night.candleTexture)
    private let halo = SKSpriteNode(texture: glowTexture(NSColor(calibratedRed: 1, green: 0.75, blue: 0.4, alpha: 1), diameter: 120))
    private let floorLight = SKSpriteNode(texture: glowTexture(NSColor(calibratedRed: 1, green: 0.6, blue: 0.3, alpha: 0.8), diameter: 200))
    private var flicker: CGFloat = 0

    override init() {
        super.init()
        alpha = 0
        isHidden = true
        dim.anchorPoint = .zero
        dim.alpha = Tuning.nightDim
        dim.zPosition = -3   // dietro a tutto: la neve e gli oggetti restano chiari
        addChild(dim)
        floorLight.blendMode = .add
        floorLight.yScale = 0.35   // un'ellisse schiacciata sul fondo
        floorLight.alpha = 0.5
        floorLight.zPosition = -2.5
        addChild(floorLight)
        candle.anchorPoint = CGPoint(x: 0.5, y: 0)
        candle.zPosition = 1.9   // davanti ai fiocchi, dietro i mucchi e gli oggetti
        addChild(candle)
        halo.blendMode = .add
        halo.zPosition = 1.85
        addChild(halo)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) non supportato")
    }

    /// Accende o spegne la notte, sfumando (con Riduci movimento cambia subito).
    func set(on: Bool, size: CGSize, calm: Bool) {
        dim.size = size
        let feet = CGPoint(x: size.width - 90, y: 0)
        candle.position = feet
        halo.position = CGPoint(x: feet.x, y: feet.y + 38)
        floorLight.position = feet
        guard on != isOn else { return }
        isOn = on
        removeAllActions()
        if on { isHidden = false }
        let fade = SKAction.fadeAlpha(to: on ? 1 : 0, duration: calm ? 0 : 2)
        run(on ? fade : .sequence([fade, .hide()]))
    }

    func step(dt: CGFloat, calm: Bool) {
        guard isOn, !calm else { return }
        flicker += dt
        halo.alpha = Tuning.flameGlow * flameFlicker(flicker)
        halo.setScale(0.95 + 0.05 * flameFlicker(flicker + 0.3))
    }

    /// Una candela bianca su un piattino d'ottone, con la fiamma.
    private static let candleTexture = drawnTexture(size: CGSize(width: 24, height: 46)) { _ in
        NSColor(calibratedRed: 0.78, green: 0.6, blue: 0.3, alpha: 1).setFill()
        NSBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 24, height: 6)).fill()
        NSColor(calibratedRed: 0.97, green: 0.94, blue: 0.86, alpha: 1).setFill()
        NSBezierPath(roundedRect: CGRect(x: 7, y: 3, width: 10, height: 28), xRadius: 2, yRadius: 2).fill()
        NSColor(white: 0.2, alpha: 1).setFill()
        NSBezierPath(rect: CGRect(x: 11.5, y: 31, width: 1, height: 3)).fill()
        NSColor(calibratedRed: 1, green: 0.6, blue: 0.15, alpha: 1).setFill()
        NSBezierPath(ovalIn: CGRect(x: 9, y: 32, width: 6, height: 13)).fill()
        NSColor(calibratedRed: 1, green: 0.95, blue: 0.7, alpha: 1).setFill()
        NSBezierPath(ovalIn: CGRect(x: 10.5, y: 33, width: 3, height: 7)).fill()
    }
}

/// Un alone: un cerchio sfumato dal centro, da usare con `blendMode = .add`.
func glowTexture(_ color: NSColor, diameter: CGFloat) -> SKTexture {
    drawnTexture(size: CGSize(width: diameter, height: diameter)) { rect in
        NSGradient(colors: [color, color.withAlphaComponent(0)])?.draw(in: NSBezierPath(ovalIn: rect), relativeCenterPosition: .zero)
    }
}

/// Il tremolio di una fiamma (0,8…1): due onde a ritmi diversi, così non si ripete a vista.
func flameFlicker(_ t: CGFloat) -> CGFloat {
    0.9 + 0.06 * sin(t * 11) + 0.04 * sin(t * 17.3 + 1)
}
