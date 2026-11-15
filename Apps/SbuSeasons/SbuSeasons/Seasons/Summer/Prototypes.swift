import AppKit
import SpriteKit

// shortcut: tre prototipi dell'Estate per la scelta di Matteo (MGS-431); resta solo quello scelto.

private func texture(_ size: CGFloat = 32, draw: @escaping (CGContext, NSRect) -> Void) -> SKTexture {
    SKTexture(image: NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
        guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
        draw(ctx, rect)
        return true
    })
}

private func glow(_ ctx: CGContext, _ rect: NSRect, _ colors: [NSColor], _ locations: [CGFloat]) {
    guard let g = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                             colors: colors.map(\.cgColor) as CFArray, locations: locations) else { return }
    let c = CGPoint(x: rect.midX, y: rect.midY)
    ctx.drawRadialGradient(g, startCenter: c, startRadius: 0, endCenter: c, endRadius: rect.width / 2, options: [])
}

/// A — Semi di tarassaco: ombrellini bianchi che scendono piano, ondeggiando molto.
struct Dandelion: Season {
    let id = "dandelion"
    var title: String { "Tarassaco" }
    let symbol = "leaf"
    var pileColor: NSColor { NSColor(srgbRed: 0.96, green: 0.95, blue: 0.90, alpha: 1) }
    func particle(depth: CGFloat) -> Particle {
        Particle(radius: 4 + depth * 7, alpha: 0.55 + depth * 0.4, fallSpeed: 10 + depth * 22,
                 swayAmplitude: .random(in: 20...50), swayFrequency: .random(in: 0.12...0.35))
    }
    func makeTexture() -> SKTexture {
        texture(64) { ctx, rect in
            let seed = CGPoint(x: rect.midX, y: rect.height * 0.18)
            let top = CGPoint(x: rect.midX, y: rect.height * 0.58)
            ctx.setLineCap(.round)
            ctx.setStrokeColor(NSColor(white: 1, alpha: 0.75).cgColor)
            ctx.setLineWidth(1.2)
            ctx.move(to: seed); ctx.addLine(to: top); ctx.strokePath()
            ctx.setLineWidth(0.9)
            for i in 0..<13 {
                let a = CGFloat.pi * (0.08 + 0.84 * CGFloat(i) / 12)
                ctx.move(to: top)
                ctx.addLine(to: CGPoint(x: top.x + cos(a) * 26, y: top.y + sin(a) * 22))
            }
            ctx.strokePath()
            ctx.setFillColor(NSColor(srgbRed: 0.55, green: 0.45, blue: 0.30, alpha: 1).cgColor)
            ctx.fillEllipse(in: CGRect(x: seed.x - 2, y: seed.y - 4, width: 4, height: 8))
        }
    }
}

/// B — Temporale estivo: gocce lunghe e veloci, quasi dritte; si posano come acqua.
struct SummerRain: Season {
    let id = "rain"
    var title: String { "Temporale" }
    let symbol = "cloud.rain"
    var pileColor: NSColor { NSColor(srgbRed: 0.62, green: 0.74, blue: 0.86, alpha: 0.85) }
    func particle(depth: CGFloat) -> Particle {
        Particle(radius: 5 + depth * 8, alpha: 0.35 + depth * 0.45, fallSpeed: 380 + depth * 520,
                 swayAmplitude: .random(in: 0...1.5), swayFrequency: .random(in: 0.2...0.5))
    }
    func makeTexture() -> SKTexture {
        texture(32) { ctx, rect in
            let w: CGFloat = 2.4
            let path = CGPath(roundedRect: CGRect(x: rect.midX - w / 2, y: 0, width: w, height: rect.height),
                              cornerWidth: w / 2, cornerHeight: w / 2, transform: nil)
            ctx.addPath(path); ctx.clip()
            let colors = [NSColor(srgbRed: 0.85, green: 0.92, blue: 1, alpha: 0.95).cgColor,
                          NSColor(srgbRed: 0.85, green: 0.92, blue: 1, alpha: 0).cgColor] as CFArray
            if let g = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: colors, locations: [0, 1]) {
                ctx.drawLinearGradient(g, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: rect.height), options: [])
            }
        }
    }
}

/// C — Lucciole: punti verde-giallo con un alone, che scendono lentissimi e si posano accesi.
struct Fireflies: Season {
    let id = "fireflies"
    var title: String { "Lucciole" }
    let symbol = "sparkle"
    var pileColor: NSColor { NSColor(srgbRed: 0.85, green: 0.95, blue: 0.45, alpha: 0.9) }
    func particle(depth: CGFloat) -> Particle {
        Particle(radius: 3 + depth * 6, alpha: .random(in: 0.35...1), fallSpeed: 4 + depth * 12,
                 swayAmplitude: .random(in: 15...45), swayFrequency: .random(in: 0.15...0.45))
    }
    func makeTexture() -> SKTexture {
        texture(32) { ctx, rect in
            let core = NSColor(srgbRed: 0.95, green: 1, blue: 0.70, alpha: 1)
            let halo = NSColor(srgbRed: 0.75, green: 0.95, blue: 0.30, alpha: 1)
            glow(ctx, rect, [core, core, halo.withAlphaComponent(0.35), halo.withAlphaComponent(0)], [0, 0.15, 0.4, 1])
        }
    }
}
