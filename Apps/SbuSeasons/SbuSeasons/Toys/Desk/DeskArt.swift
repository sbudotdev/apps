import AppKit

/// I disegni delle decorazioni della scrivania (SBU-187), fatti con AppKit: il disegno è nostro.
/// `phase` (in secondi) fa tremare le fiamme e accendere le lampadine a turno; ferma a 0 resta un disegno fisso.
enum DeskArt {
    /// Disegna `item` in una vista grande quanto `item.frame` (origine della vista = `frame.origin`).
    static func draw(_ item: DeskItem, phase: CGFloat) {
        let frame = item.frame
        if item.kind == .lights {
            lights(item.wire.map { CGPoint(x: $0.x - frame.minX, y: $0.y - frame.minY) }, scale: item.scale, phase: phase)
            return
        }
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.saveGState()
        context.translateBy(x: frame.width / 2, y: frame.height / 2)
        context.rotate(by: item.rotation)
        context.scaleBy(x: item.scale, y: item.scale)
        let size = item.kind.size
        let r = CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height)
        switch item.kind {
        case .lights: break
        case .garland: garland(in: r)
        case .stocking: stocking(in: r)
        case .candle: candle(in: r, phase: phase)
        case .bonfire: bonfire(in: r, phase: phase)
        case .penguin: penguin(in: r)
        case .snowGlobe: snowGlobe(in: r)
        }
        context.restoreGState()
    }

    /// Anche i colori «Multicolore» delle Luci in alto (SBU-229).
    static let bulbColors: [NSColor] = [.systemRed, .systemYellow, .systemTeal, .systemOrange, .systemPink, .systemGreen]

    // MARK: - Luci

    private static func lights(_ wire: [CGPoint], scale: CGFloat, phase: CGFloat) {
        let path = NSBezierPath()
        path.move(to: wire[0])
        wire.dropFirst().forEach(path.line(to:))
        path.lineWidth = 1.2
        NSColor(calibratedRed: 0.1, green: 0.25, blue: 0.12, alpha: 1).setStroke()
        path.stroke()
        // Le lampadine lungo il filo, una ogni `bulbGap` pt; si accendono e si spengono piano, a turno.
        var walked: CGFloat = 0
        var next: CGFloat = Tuning.bulbGap / 2
        var index = 0
        let radius = Tuning.bulbRadius * scale
        for (a, b) in zip(wire, wire.dropFirst()) {
            let step = hypot(b.x - a.x, b.y - a.y)
            while next <= walked + step, step > 0 {
                let t = (next - walked) / step
                let p = CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
                let glow = phase == 0 ? 1 : 0.65 + 0.35 * sin(phase * 3 + CGFloat(index) * 1.7)
                let color = bulbColors[index % bulbColors.count]
                color.withAlphaComponent(0.25 * glow).setFill()
                NSBezierPath(ovalIn: CGRect(x: p.x - radius * 1.8, y: p.y - radius * 2.3, width: radius * 3.6, height: radius * 3.6)).fill()
                color.withAlphaComponent(glow).setFill()
                NSBezierPath(ovalIn: CGRect(x: p.x - radius * 0.8, y: p.y - radius * 1.9, width: radius * 1.6, height: radius * 2.2)).fill()
                next += Tuning.bulbGap
                index += 1
            }
            walked += step
        }
        // Le due estremità: un tappo scuro, da prendere per spostarle.
        NSColor(calibratedRed: 0.1, green: 0.25, blue: 0.12, alpha: 1).setFill()
        for end in [wire[0], wire[wire.count - 1]] {
            NSBezierPath(ovalIn: CGRect(x: end.x - 3, y: end.y - 3, width: 6, height: 6)).fill()
        }
    }

    // MARK: - Ghirlanda

    private static func garland(in r: CGRect) {
        // Rami verdi lungo un arco che pende, bacche rosse e un fiocco in mezzo.
        let greens = [NSColor(calibratedRed: 0.1, green: 0.38, blue: 0.2, alpha: 1),
                      NSColor(calibratedRed: 0.16, green: 0.5, blue: 0.27, alpha: 1)]
        let count = 18
        for i in 0...count {
            let t = CGFloat(i) / CGFloat(count)
            let x = r.minX + 10 + (r.width - 20) * t
            let y = r.maxY - 12 - (r.height - 26) * 4 * t * (1 - t)
            greens[i % 2].setFill()
            NSBezierPath(ovalIn: CGRect(x: x - 8, y: y - 6, width: 16, height: 12)).fill()
            if i % 3 == 1 {
                NSColor.systemRed.setFill()
                NSBezierPath(ovalIn: CGRect(x: x - 2, y: y - 2, width: 4, height: 4)).fill()
            }
        }
        let knot = CGPoint(x: r.midX, y: r.minY + 14)
        NSColor(calibratedRed: 0.78, green: 0.12, blue: 0.16, alpha: 1).setFill()
        for side in [-1.0, 1.0] {
            let loop = NSBezierPath()
            loop.move(to: knot)
            loop.line(to: CGPoint(x: knot.x + side * 11, y: knot.y + 6))
            loop.line(to: CGPoint(x: knot.x + side * 11, y: knot.y - 5))
            loop.close()
            loop.fill()
            let tail = NSBezierPath()
            tail.move(to: knot)
            tail.line(to: CGPoint(x: knot.x + side * 7, y: knot.y - 12))
            tail.line(to: CGPoint(x: knot.x + side * 2, y: knot.y - 12))
            tail.close()
            tail.fill()
        }
        NSBezierPath(ovalIn: CGRect(x: knot.x - 3, y: knot.y - 3, width: 6, height: 6)).fill()
    }

    // MARK: - Calza

    private static func stocking(in r: CGRect) {
        let red = NSColor(calibratedRed: 0.76, green: 0.12, blue: 0.16, alpha: 1)
        let sock = NSBezierPath()
        sock.move(to: CGPoint(x: r.minX + 10, y: r.maxY - 12))
        sock.line(to: CGPoint(x: r.minX + 10, y: r.minY + 20))
        sock.curve(to: CGPoint(x: r.minX + 26, y: r.minY + 2),
                   controlPoint1: CGPoint(x: r.minX + 10, y: r.minY + 8), controlPoint2: CGPoint(x: r.minX + 16, y: r.minY + 2))
        sock.line(to: CGPoint(x: r.maxX - 6, y: r.minY + 2))
        sock.curve(to: CGPoint(x: r.maxX - 10, y: r.minY + 20),
                   controlPoint1: CGPoint(x: r.maxX + 2, y: r.minY + 2), controlPoint2: CGPoint(x: r.maxX, y: r.minY + 18))
        sock.line(to: CGPoint(x: r.minX + 30, y: r.minY + 22))
        sock.line(to: CGPoint(x: r.minX + 30, y: r.maxY - 12))
        sock.close()
        red.setFill()
        sock.fill()
        // Tallone e punta bianchi, il bordo di pelliccia, il gancio.
        NSColor.white.setFill()
        NSBezierPath(ovalIn: CGRect(x: r.maxX - 12, y: r.minY + 2, width: 9, height: 10)).fill()
        NSBezierPath(roundedRect: CGRect(x: r.minX + 7, y: r.maxY - 16, width: 26, height: 10), xRadius: 5, yRadius: 5).fill()
        let hook = NSBezierPath(ovalIn: CGRect(x: r.minX + 8, y: r.maxY - 8, width: 6, height: 7))
        hook.lineWidth = 1.2
        NSColor(white: 0.35, alpha: 1).setStroke()
        hook.stroke()
    }

    // MARK: - Candela

    private static func candle(in r: CGRect, phase: CGFloat) {
        // Una candela rossa con la cera che cola, su un piattino d'ottone.
        let body = CGRect(x: r.midX - 8, y: r.minY + 3, width: 16, height: r.height * 0.55)
        NSColor(calibratedRed: 0.72, green: 0.13, blue: 0.16, alpha: 1).setFill()
        NSBezierPath(roundedRect: body, xRadius: 2, yRadius: 2).fill()
        NSColor(calibratedRed: 0.86, green: 0.3, blue: 0.3, alpha: 1).setFill()
        NSBezierPath(roundedRect: CGRect(x: body.minX, y: body.maxY - 4, width: body.width, height: 4), xRadius: 2, yRadius: 2).fill()
        NSBezierPath(roundedRect: CGRect(x: body.minX + 3, y: body.maxY - 11, width: 3, height: 9), xRadius: 1.5, yRadius: 1.5).fill()
        NSColor(calibratedRed: 0.8, green: 0.62, blue: 0.25, alpha: 1).setFill()
        NSBezierPath(roundedRect: CGRect(x: r.minX, y: r.minY, width: r.width, height: 4), xRadius: 2, yRadius: 2).fill()
        NSColor(white: 0.2, alpha: 1).setFill()
        NSBezierPath(rect: CGRect(x: r.midX - 0.6, y: body.maxY, width: 1.2, height: 4)).fill()
        flame(at: CGPoint(x: r.midX, y: body.maxY + 3), height: r.height * 0.38, phase: phase)
    }

    /// Una fiamma che trema: alone, fuoco arancione e cuore giallo.
    private static func flame(at base: CGPoint, height: CGFloat, phase: CGFloat, seed: CGFloat = 0) {
        let flicker = phase == 0 ? 1 : 0.88 + 0.12 * sin(phase * 9 + seed) * sin(phase * 5.3 + seed * 2)
        let sway = phase == 0 ? 0 : sin(phase * 4.1 + seed) * height * 0.08
        let h = height * flicker
        NSColor.systemOrange.withAlphaComponent(0.18 * Tuning.flameGlow).setFill()
        NSBezierPath(ovalIn: CGRect(x: base.x - h * 0.7, y: base.y - h * 0.25, width: h * 1.4, height: h * 1.4)).fill()
        for (scale, color) in [(1.0, NSColor.systemOrange), (0.6, NSColor.systemYellow)] {
            let w = h * 0.36 * scale, top = h * scale
            let fire = NSBezierPath()
            fire.move(to: CGPoint(x: base.x, y: base.y))
            fire.curve(to: CGPoint(x: base.x + sway, y: base.y + top),
                       controlPoint1: CGPoint(x: base.x + w, y: base.y), controlPoint2: CGPoint(x: base.x + w * 0.6, y: base.y + top * 0.6))
            fire.curve(to: CGPoint(x: base.x, y: base.y),
                       controlPoint1: CGPoint(x: base.x - w * 0.6, y: base.y + top * 0.6), controlPoint2: CGPoint(x: base.x - w, y: base.y))
            color.setFill()
            fire.fill()
        }
    }

    // MARK: - Falò

    private static func bonfire(in r: CGRect, phase: CGFloat) {
        // Pietre, due ciocchi incrociati, tre fiamme e qualche scintilla.
        NSColor(white: 0.55, alpha: 1).setFill()
        for i in 0..<6 {
            NSBezierPath(ovalIn: CGRect(x: r.minX + 2 + CGFloat(i) * 10.5, y: r.minY, width: 11, height: 7)).fill()
        }
        let wood = NSColor(calibratedRed: 0.45, green: 0.28, blue: 0.15, alpha: 1)
        wood.setFill()
        for side in [-1.0, 1.0] {
            let log = NSBezierPath(roundedRect: CGRect(x: -22, y: -4, width: 44, height: 8), xRadius: 4, yRadius: 4)
            var t = AffineTransform(translationByX: r.midX, byY: r.minY + 10)
            t.rotate(byRadians: side * 0.32)
            log.transform(using: t)
            log.fill()
        }
        flame(at: CGPoint(x: r.midX - 10, y: r.minY + 12), height: r.height * 0.5, phase: phase, seed: 1)
        flame(at: CGPoint(x: r.midX + 10, y: r.minY + 12), height: r.height * 0.55, phase: phase, seed: 2)
        flame(at: CGPoint(x: r.midX, y: r.minY + 12), height: r.height * 0.75, phase: phase, seed: 3)
        guard phase != 0 else { return }
        NSColor.systemYellow.setFill()
        for i in 0..<4 {
            let rise = (phase * 0.9 + CGFloat(i) * 0.27).truncatingRemainder(dividingBy: 1)
            let x = r.midX + sin(CGFloat(i) * 2.4 + phase) * 14
            NSBezierPath(ovalIn: CGRect(x: x, y: r.minY + 20 + rise * (r.height - 22), width: 2, height: 2)).fill()
        }
    }

    // MARK: - Pinguino

    private static func penguin(in r: CGRect) {
        let black = NSColor(white: 0.12, alpha: 1)
        let orange = NSColor(calibratedRed: 0.98, green: 0.6, blue: 0.15, alpha: 1)
        orange.setFill()
        for x in [r.midX - 11, r.midX + 2] { NSBezierPath(ovalIn: CGRect(x: x, y: r.minY, width: 10, height: 5)).fill() }
        black.setFill()
        NSBezierPath(ovalIn: CGRect(x: r.minX + 2, y: r.minY + 3, width: r.width - 4, height: r.height * 0.72)).fill()
        for side in [-1.0, 1.0] {
            NSBezierPath(ovalIn: CGRect(x: r.midX + side * 17 - 4, y: r.minY + 10, width: 8, height: 20)).fill()
        }
        NSBezierPath(ovalIn: CGRect(x: r.midX - 13, y: r.maxY - 27, width: 26, height: 26)).fill()
        NSColor.white.setFill()
        NSBezierPath(ovalIn: CGRect(x: r.midX - 12, y: r.minY + 5, width: 24, height: r.height * 0.55)).fill()
        NSBezierPath(ovalIn: CGRect(x: r.midX - 9, y: r.maxY - 22, width: 18, height: 16)).fill()
        black.setFill()
        for x in [r.midX - 5.5, r.midX + 3.5] { NSBezierPath(ovalIn: CGRect(x: x, y: r.maxY - 13, width: 2.5, height: 3)).fill() }
        let beak = NSBezierPath()
        beak.move(to: CGPoint(x: r.midX - 3, y: r.maxY - 16))
        beak.line(to: CGPoint(x: r.midX + 3, y: r.maxY - 16))
        beak.line(to: CGPoint(x: r.midX, y: r.maxY - 21))
        beak.close()
        orange.setFill()
        beak.fill()
        // Una sciarpina rossa.
        NSColor(calibratedRed: 0.78, green: 0.12, blue: 0.16, alpha: 1).setFill()
        NSBezierPath(roundedRect: CGRect(x: r.midX - 11, y: r.maxY - 29, width: 22, height: 4), xRadius: 2, yRadius: 2).fill()
    }

    // MARK: - Palla di vetro

    private static func snowGlobe(in r: CGRect) {
        // Base di legno, il vetro azzurrino, dentro un alberello e la neve; un riflesso.
        let base = NSBezierPath()
        base.move(to: CGPoint(x: r.minX + 4, y: r.minY))
        base.line(to: CGPoint(x: r.maxX - 4, y: r.minY))
        base.line(to: CGPoint(x: r.maxX - 10, y: r.minY + 12))
        base.line(to: CGPoint(x: r.minX + 10, y: r.minY + 12))
        base.close()
        NSColor(calibratedRed: 0.5, green: 0.32, blue: 0.18, alpha: 1).setFill()
        base.fill()
        let glass = CGRect(x: r.midX - 23, y: r.minY + 9, width: 46, height: 46)
        NSColor(calibratedRed: 0.82, green: 0.92, blue: 0.98, alpha: 0.9).setFill()
        NSBezierPath(ovalIn: glass).fill()
        NSGraphicsContext.saveGraphicsState()
        NSBezierPath(ovalIn: glass).addClip()
        NSColor.white.setFill()
        NSBezierPath(ovalIn: CGRect(x: glass.minX - 4, y: glass.minY - 10, width: glass.width + 8, height: 22)).fill()
        let tree = NSBezierPath()
        tree.move(to: CGPoint(x: r.midX - 10, y: glass.minY + 10))
        tree.line(to: CGPoint(x: r.midX + 10, y: glass.minY + 10))
        tree.line(to: CGPoint(x: r.midX, y: glass.minY + 34))
        tree.close()
        NSColor(calibratedRed: 0.13, green: 0.42, blue: 0.24, alpha: 1).setFill()
        tree.fill()
        NSColor.white.setFill()
        for (x, y) in [(-15.0, 30.0), (-8, 38), (6, 42), (14, 28), (-3, 24), (16, 36), (-17, 20), (9, 18)] {
            NSBezierPath(ovalIn: CGRect(x: r.midX + x, y: glass.minY + y, width: 2.4, height: 2.4)).fill()
        }
        NSColor.white.withAlphaComponent(0.6).setFill()
        NSBezierPath(ovalIn: CGRect(x: glass.minX + 8, y: glass.maxY - 16, width: 8, height: 10)).fill()
        NSGraphicsContext.restoreGraphicsState()
    }
}
