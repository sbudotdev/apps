import AppKit

/// Il disegno delle Luci in alto (SBU-229), fatto a codice come quello delle «Luci da appendere» di Decora (`DeskArt`):
/// lo stesso filo verde scuro, lampadine con l'alone, qui appese sotto il filo e di tre forme.
enum TopLightsArt {
    private static let wireColor = NSColor(calibratedRed: 0.1, green: 0.25, blue: 0.12, alpha: 1)

    static func colors(_ palette: TopLights.Palette, single: TopLights.SingleColor) -> [NSColor] {
        switch palette {
        case .multicolor: DeskArt.bulbColors
        case .warm: [.systemOrange, NSColor(calibratedRed: 1, green: 0.8, blue: 0.45, alpha: 1), .systemRed, .systemYellow]
        case .cold: [.systemTeal, NSColor(calibratedRed: 0.85, green: 0.93, blue: 1, alpha: 1), .systemBlue, .systemCyan]
        case .single: [color(single)]
        }
    }

    private static func color(_ single: TopLights.SingleColor) -> NSColor {
        switch single {
        case .red: .systemRed
        case .gold: NSColor(calibratedRed: 1, green: 0.78, blue: 0.25, alpha: 1)
        case .white: NSColor(calibratedRed: 1, green: 0.97, blue: 0.88, alpha: 1)
        case .blue: .systemBlue
        case .green: .systemGreen
        }
    }

    /// Tutto il filo in un rettangolo largo quanto lo schermo: i ganci sul bordo in alto, `time` in secondi.
    static func draw(in bounds: CGRect, colors: [NSColor], shape: TopLights.Shape, animation: TopLights.Animation, time: Double) {
        let width = bounds.width
        let top = bounds.maxY - 2
        let wire = NSBezierPath()
        wire.move(to: CGPoint(x: 0, y: top))
        for x in stride(from: 0, through: width, by: 6) { wire.line(to: CGPoint(x: x, y: top - TopLights.sag(at: x, width: width))) }
        wire.line(to: CGPoint(x: width, y: top))
        wire.lineWidth = 1.2
        wireColor.setStroke()
        wire.stroke()
        wireColor.setFill()
        for x in TopLights.hookXs(width: width) { NSBezierPath(ovalIn: CGRect(x: x - 2.5, y: top - 2.5, width: 5, height: 5)).fill() }

        let r = Tuning.topLightsBulbRadius
        for (index, x) in TopLights.bulbXs(width: width).enumerated() {
            let hang = top - TopLights.sag(at: x, width: width)
            let glow = TopLights.glow(index: index, time: time, animation: animation)
            let color = colors[index % colors.count]
            // Il portalampada scuro attaccato al filo, poi la lampadina sotto.
            wireColor.setFill()
            NSBezierPath(roundedRect: CGRect(x: x - r * 0.45, y: hang - r * 0.9, width: r * 0.9, height: r * 0.9), xRadius: 1, yRadius: 1).fill()
            let center = CGPoint(x: x, y: hang - r * 0.9 - r)
            color.withAlphaComponent(0.28 * glow).setFill()
            NSBezierPath(ovalIn: CGRect(x: center.x - r * 2, y: center.y - r * 2.2, width: r * 4, height: r * 4)).fill()
            (color.shadow(withLevel: (1 - glow) * 0.55) ?? color).setFill()
            bulb(shape, center: center, radius: r).fill()
            NSColor.white.withAlphaComponent(0.55 * glow).setFill()
            NSBezierPath(ovalIn: CGRect(x: center.x - r * 0.5, y: center.y + r * 0.05, width: r * 0.45, height: r * 0.5)).fill()
        }
    }

    /// La lampadina: tonda, a goccia (la punta in giù) o a stella, con la parte alta a `radius` sopra `center`.
    private static func bulb(_ shape: TopLights.Shape, center c: CGPoint, radius r: CGFloat) -> NSBezierPath {
        switch shape {
        case .round:
            return NSBezierPath(ovalIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
        case .drop:
            let tip = CGPoint(x: c.x, y: c.y - r * 2.1)
            let path = NSBezierPath()
            path.move(to: tip)
            path.curve(to: CGPoint(x: c.x - r, y: c.y), controlPoint1: CGPoint(x: c.x - r * 0.25, y: tip.y + r * 0.6),
                       controlPoint2: CGPoint(x: c.x - r, y: c.y - r * 0.7))
            path.appendArc(withCenter: c, radius: r, startAngle: 180, endAngle: 0, clockwise: true)
            path.curve(to: tip, controlPoint1: CGPoint(x: c.x + r, y: c.y - r * 0.7),
                       controlPoint2: CGPoint(x: c.x + r * 0.25, y: tip.y + r * 0.6))
            path.close()
            return path
        case .star:
            let path = NSBezierPath()
            let outer = r * 1.45, inner = r * 0.62
            // Il centro un po' più giù: la punta in alto tocca il portalampada.
            let middle = CGPoint(x: c.x, y: c.y + r - outer)
            for i in 0..<10 {
                let angle = CGFloat.pi / 2 + CGFloat(i) * .pi / 5
                let radius = i.isMultiple(of: 2) ? outer : inner
                let p = CGPoint(x: middle.x + cos(angle) * radius, y: middle.y + sin(angle) * radius)
                if i == 0 { path.move(to: p) } else { path.line(to: p) }
            }
            path.close()
            return path
        }
    }
}
