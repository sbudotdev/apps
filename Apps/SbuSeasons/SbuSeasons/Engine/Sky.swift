import AppKit
import SpriteKit

extension Lightning {
    /// Quanto è illuminato il cielo `t` secondi dopo l'inizio di un lampo (0…1): due bagliori ravvicinati,
    /// poi la luce si spegne piano. Dopo 0,8 s è finito.
    static func flash(at t: CGFloat) -> CGFloat {
        guard t >= 0, t < 0.8 else { return 0 }
        let first = max(0, 1 - abs(t - 0.04) / 0.06)
        let second = 0.75 * max(0, 1 - abs(t - 0.22) / 0.08)
        let fade = t > 0.22 ? 0.3 * (1 - (t - 0.22) / 0.58) : 0
        return max(first, second, fade)
    }
}

/// I banchi a tutto schermo (nebbia, nuvole) e i lampi della stagione. Pochi sprite grandi e sfumati, disegnati una
/// volta: muoverli costa poco (CPU misurata nel README).
final class Sky: SKNode {
    private struct Mass {
        let node: SKSpriteNode
        let kind: Bank
        let speed: CGFloat
        let alpha: CGFloat
    }
    private var masses: [Mass] = []
    private var lightning: Lightning?
    /// Il cielo dietro le nuvole, che si illumina col lampo.
    private var glow: SKSpriteNode?
    private var nextStrike: CGFloat = 0
    private var strike: CGFloat?
    private var thunder: CGFloat?
    private var clock: CGFloat = 0
    private var built: (season: String, size: CGSize, amount: CGFloat)?

    /// Quanto è illuminato il cielo adesso (0 = nessun lampo).
    private(set) var flash: CGFloat = 0
    /// I banchi: posizione, misura e trasparenza (per i test).
    var bankNodes: [SKSpriteNode] { masses.map(\.node) }

    /// Prepara i banchi della stagione. Con la stessa stagione e lo stesso schermo, al cambio d'intensità
    /// ne toglie o ne aggiunge (da sinistra, fuori schermo): quelli che ci sono non saltano.
    func set(_ season: any Season, size: CGSize, amount: CGFloat) {
        let same = built.map { $0.season == season.id && $0.size == size } ?? false
        if same, built?.amount == amount { return }
        built = (season.id, size, amount)
        if !same {
            removeAllChildren()
            masses = []
            glow = nil
            lightning = season.lightning
            strike = nil
            flash = 0
            nextStrike = clock + .random(in: lightning?.every ?? 1...1) * 0.3
        }
        guard size.width > 0, size.height > 0 else { return }
        if lightning != nil, glow == nil {
            let node = SKSpriteNode(texture: Self.glowTexture)
            node.anchorPoint = CGPoint(x: 0.5, y: 1)
            node.position = CGPoint(x: size.width / 2, y: size.height)
            node.size = CGSize(width: size.width, height: size.height * 0.7)
            node.alpha = 0
            node.zPosition = -2
            addChild(node)
            glow = node
        }
        for bank in season.banks {
            let count = max(1, Int((CGFloat(bank.count) * size.width / 1440 * amount).rounded()))
            let mine = masses.indices.filter { masses[$0].kind.shape == bank.shape && masses[$0].kind.band == bank.band }
            for i in mine.dropFirst(count).reversed() {
                masses[i].node.removeFromParent()
                masses.remove(at: i)
            }
            for _ in mine.count..<max(count, mine.count) {
                let mass = makeMass(bank, size: size)
                // All'inizio sparsi su tutto lo schermo; quelli in più arrivano da sinistra.
                mass.node.position.x = same ? -mass.node.size.width / 2 : .random(in: 0...size.width)
                masses.append(mass)
            }
        }
    }

    private func makeMass(_ bank: Bank, size: CGSize) -> Mass {
        let height = CGFloat.random(in: bank.height)
        let node = SKSpriteNode(texture: Self.textures(bank.shape).randomElement())
        node.size = CGSize(width: height * .random(in: bank.aspect), height: height)
        node.position = CGPoint(x: 0, y: size.height * .random(in: bank.band))
        node.color = bank.color
        node.colorBlendFactor = 1
        let alpha = CGFloat.random(in: bank.alpha)
        node.alpha = alpha
        // Le nuvole stanno dietro alla pioggia, la nebbia davanti alle particelle (ma dietro ai mucchi e agli oggetti).
        node.zPosition = bank.shape == .cloud ? -1 : 1.8
        if Bool.random() { node.xScale = -1 }
        addChild(node)
        return Mass(node: node, kind: bank, speed: .random(in: bank.speed), alpha: alpha)
    }

    func step(dt: CGFloat, width: CGFloat, calm: Bool) {
        clock += dt
        let pace = calm ? 0.4 : 1
        for mass in masses {
            let half = mass.node.size.width / 2
            mass.node.position.x += mass.speed * pace * dt
            if mass.node.position.x - half > width {
                mass.node.position.x = -half - .random(in: 0...200)
            }
        }
        guard let lightning else { return }
        // Con Riduci movimento niente lampi: è luce che lampeggia.
        if !calm, clock >= nextStrike {
            strike = clock
            thunder = clock + .random(in: 1.5...4)   // lontano: il tuono arriva dopo
            nextStrike = clock + .random(in: lightning.every)
        }
        if let at = thunder, clock >= at {
            thunder = nil
            SoundBoard.shared.play("tuono")
        }
        let level = calm ? 0 : strike.map { Lightning.flash(at: clock - $0) * lightning.strength } ?? 0
        guard level != flash else { return }
        flash = level
        glow?.alpha = level * 0.35
        for mass in masses where mass.kind.shape == .cloud {
            mass.node.color = mass.kind.color.blended(withFraction: level, of: .white) ?? mass.kind.color
            mass.node.alpha = min(1, mass.alpha + level * 0.3)
        }
    }

    // MARK: - Disegni (bianchi, tinti dal colore del banco)

    private static func textures(_ shape: Bank.Shape) -> [SKTexture] {
        switch shape {
        case .mist: mist
        case .cloud: clouds
        }
    }

    private static let mist: [SKTexture] = (0..<3).map { _ in
        draw(NSSize(width: 256, height: 64)) { ctx, rect in
            // Qualche ellisse sfumata, lunga e bassa, una sull'altra: uno strato irregolare.
            for _ in 0..<5 {
                let w = rect.width * .random(in: 0.35...0.6), h = rect.height * .random(in: 0.5...0.9)
                puff(ctx, CGRect(x: .random(in: 0...(rect.width - w)), y: (rect.height - h) / 2 + .random(in: -6...6),
                                 width: w, height: h), alpha: .random(in: 0.5...0.9))
            }
        }
    }

    private static let clouds: [SKTexture] = (0..<3).map { _ in
        draw(NSSize(width: 256, height: 128)) { ctx, rect in
            // Un cumulo: una fila di sbuffi in basso, due o tre più grandi sopra.
            for i in 0..<6 {
                let d = rect.height * .random(in: 0.45...0.6)
                let x = rect.width * (0.08 + CGFloat(i) * 0.14) + .random(in: -6...6)
                puff(ctx, CGRect(x: x - d / 2 + 20, y: rect.height * 0.12, width: d * 1.3, height: d), alpha: 0.9)
            }
            for _ in 0..<3 {
                let d = rect.height * .random(in: 0.6...0.85)
                puff(ctx, CGRect(x: .random(in: rect.width * 0.2...rect.width * 0.65), y: rect.height * 0.2,
                                 width: d, height: d), alpha: 0.85)
            }
        }
    }

    private static let glowTexture = draw(NSSize(width: 16, height: 64)) { ctx, rect in
        let colors = [NSColor.white.cgColor, NSColor.white.withAlphaComponent(0).cgColor] as CFArray
        guard let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: colors, locations: [0, 1])
        else { return }
        ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: rect.maxY), end: .zero, options: [])
    }

    /// Un'ellisse bianca con il bordo sfumato nel trasparente.
    private static func puff(_ ctx: CGContext, _ r: CGRect, alpha: CGFloat) {
        let colors = [NSColor.white.withAlphaComponent(alpha).cgColor, NSColor.white.withAlphaComponent(alpha * 0.6).cgColor,
                      NSColor.white.withAlphaComponent(0).cgColor] as CFArray
        guard let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: colors,
                                        locations: [0, 0.5, 1]) else { return }
        ctx.saveGState()
        ctx.translateBy(x: r.midX, y: r.midY)
        ctx.scaleBy(x: r.width / r.height, y: 1)
        ctx.drawRadialGradient(gradient, startCenter: .zero, startRadius: 0, endCenter: .zero, endRadius: r.height / 2, options: [])
        ctx.restoreGState()
    }

    private static func draw(_ size: NSSize, _ body: @escaping (CGContext, CGRect) -> Void) -> SKTexture {
        SKTexture(image: NSImage(size: size, flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            body(ctx, rect)
            return true
        })
    }
}
