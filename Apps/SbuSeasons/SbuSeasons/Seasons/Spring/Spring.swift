import AppKit
import SpriteKit

/// La primavera: petali di ciliegio, leggeri, che scendono lenti e svolazzano larghi;
/// lenti come sono, il vento e il cursore li portano lontano. Si posano rosa chiaro.
struct Spring: Season {
    static let id = "spring"
    var id: String { Self.id }
    var title: String { String(localized: "Primavera") }
    let symbol = "camera.macro"
    var pileColor: NSColor { SpringTuning.settled }

    func particle(depth: CGFloat) -> Particle {
        Particle(
            radius: 3 + depth * 5,
            alpha: SpringTuning.opacity.lowerBound + depth * (SpringTuning.opacity.upperBound - SpringTuning.opacity.lowerBound),
            fallSpeed: 9 + depth * 20,
            swayAmplitude: .random(in: SpringTuning.flutter),
            swayFrequency: .random(in: 0.18...0.45)
        )
    }

    /// Un petalo: goccia con la tacca in punta, rosa più carico alla base e chiaro in punta,
    /// inclinato di lato perché non sembri un'icona.
    func makeTexture() -> SKTexture {
        let side: CGFloat = 64
        let image = NSImage(size: NSSize(width: side, height: side), flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            ctx.translateBy(x: rect.midX, y: rect.midY)
            ctx.rotate(by: SpringTuning.tilt)
            // Base in basso (0, -26), punta con la tacca in alto (0, 22).
            let petal = CGMutablePath()
            petal.move(to: CGPoint(x: 0, y: -26))
            petal.addCurve(to: CGPoint(x: -4, y: 24), control1: CGPoint(x: -26, y: -8), control2: CGPoint(x: -20, y: 26))
            petal.addLine(to: CGPoint(x: 0, y: 17))
            petal.addLine(to: CGPoint(x: 4, y: 24))
            petal.addCurve(to: CGPoint(x: 0, y: -26), control1: CGPoint(x: 20, y: 26), control2: CGPoint(x: 26, y: -8))
            petal.closeSubpath()
            ctx.addPath(petal)
            ctx.clip()
            let colors = [SpringTuning.base.cgColor, SpringTuning.tip.cgColor] as CFArray
            guard let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: colors, locations: [0, 1])
            else { return false }
            ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: -26), end: CGPoint(x: 0, y: 22), options: [])
            return true
        }
        return SKTexture(image: image)
    }
}

/// I colori e i numeri fissi dei petali: contenuto, non interfaccia (li approva Matteo sulla registrazione).
nonisolated enum SpringTuning {
    /// Opacità di un petalo: i lontani più trasparenti.
    static let opacity: ClosedRange<CGFloat> = 0.6...0.95
    /// Oscillazione laterale in punti: molto più ampia della neve (8…26), un petalo svolazza.
    static let flutter: ClosedRange<CGFloat> = 30...70
    static let tilt: CGFloat = .pi / 7
    static let base = NSColor(srgbRed: 0.93, green: 0.62, blue: 0.70, alpha: 1)
    static let tip = NSColor(srgbRed: 0.99, green: 0.89, blue: 0.91, alpha: 1)
    /// I petali posati sulle finestre e sul Dock.
    static let settled = NSColor(srgbRed: 0.98, green: 0.84, blue: 0.87, alpha: 1)
}
