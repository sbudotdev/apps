import AppKit
import SpriteKit

/// L'arcobaleno dopo la pioggia (SBU-177, Impostazioni → Meteo): quando pioggia o temporale lasciano il posto a un
/// altro effetto, un arco tenue sale piano dietro a tutto, resta un po' e sfuma. Con Riduci movimento compare
/// e sparisce senza dissolvenza.
final class Rainbow: SKNode {
    private var arc: SKSpriteNode?
    private var age: CGFloat?

    var isShowing: Bool { age != nil }

    /// L'arcobaleno va mostrato? Sì se si passa dalla pioggia (o dal temporale) a un effetto asciutto.
    static func follows(from: String, to: String) -> Bool {
        let wet = [Rain.id, Storm.id]
        return wet.contains(from) && !wet.contains(to)
    }

    /// Quanto si vede `t` secondi dopo che è comparso (0…1).
    nonisolated static func alpha(at t: CGFloat, calm: Bool) -> CGFloat {
        guard t >= 0, t < Tuning.rainbowLife else { return 0 }
        if calm { return 1 }
        return min(1, t / Tuning.rainbowFadeIn, (Tuning.rainbowLife - t) / Tuning.rainbowFadeOut)
    }

    func show(size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        arc?.removeFromParent()
        let node = SKSpriteNode(texture: Self.texture)
        let width = min(size.width * 0.8, size.height * 1.4)
        node.size = CGSize(width: width, height: width / 2)
        node.anchorPoint = CGPoint(x: 0.5, y: 0)
        node.position = CGPoint(x: size.width / 2, y: size.height * 0.3)
        node.alpha = 0
        node.zPosition = -3   // dietro al cielo del lampo, alle nuvole e a tutto il resto
        addChild(node)
        arc = node
        age = 0
    }

    func step(dt: CGFloat, calm: Bool) {
        guard let age, let arc else { return }
        let now = age + dt
        guard now < Tuning.rainbowLife else {
            arc.removeFromParent()
            self.arc = nil
            self.age = nil
            return
        }
        self.age = now
        arc.alpha = Self.alpha(at: now, calm: calm) * Tuning.rainbowOpacity
    }

    /// Le bande, dall'interno (viola) all'esterno (rosso): contenuto, non interfaccia (le approva Matteo).
    static let bands: [NSColor] = [
        NSColor(srgbRed: 0.55, green: 0.36, blue: 0.85, alpha: 1),
        NSColor(srgbRed: 0.30, green: 0.48, blue: 0.95, alpha: 1),
        NSColor(srgbRed: 0.30, green: 0.75, blue: 0.55, alpha: 1),
        NSColor(srgbRed: 0.98, green: 0.88, blue: 0.35, alpha: 1),
        NSColor(srgbRed: 0.98, green: 0.62, blue: 0.25, alpha: 1),
        NSColor(srgbRed: 0.92, green: 0.30, blue: 0.28, alpha: 1),
    ]

    /// Mezzo anello sfumato ai bordi, che svanisce verso le due basi.
    private static let texture: SKTexture = drawnTexture(size: CGSize(width: 512, height: 256)) { rect in
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        let center = CGPoint(x: rect.midX, y: 0)
        let colors = ([NSColor.clear] + bands + [NSColor.clear]).map(\.cgColor) as CFArray
        let stops = (0...(bands.count + 1)).map { CGFloat($0) / CGFloat(bands.count + 1) }
        guard let ring = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: colors, locations: stops),
              let fade = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                                    colors: [NSColor.clear.cgColor, NSColor.white.cgColor] as CFArray, locations: [0, 1])
        else { return }
        ctx.drawRadialGradient(ring, startCenter: center, startRadius: rect.width * 0.36, endCenter: center,
                               endRadius: rect.width * 0.5, options: [])
        ctx.setBlendMode(.destinationIn)
        ctx.drawLinearGradient(fade, start: .zero, end: CGPoint(x: 0, y: rect.height * 0.45), options: [.drawsAfterEndLocation])
    }
}
