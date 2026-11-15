import AppKit
import SpriteKit

/// La scena SpriteKit che disegna e muove i fiocchi.
///
/// Coordinate: origine in basso a sinistra (come SpriteKit e come `NSEvent.mouseLocation`),
/// un punto della scena = un punto dello schermo.
final class SnowScene: SKScene {

    // MARK: - Parametri (giocaci pure)

    /// Raggio entro cui il cursore influenza i fiocchi, in punti.
    private let cursorRadius: CGFloat = 90
    /// Quanto forte il cursore "scosta" i fiocchi anche da fermo (pt/s²).
    private let cursorRepel: CGFloat = 2200
    /// Quanto un movimento veloce del mouse trascina con sé i fiocchi (0…1).
    private let cursorDrag: CGFloat = 0.55
    /// Quanto velocemente la spinta del cursore si esaurisce (più alto = si fermano prima).
    private let damping: CGFloat = 1.8
    /// Forza massima del vento, in pt/s.
    private let maxWind: CGFloat = 14

    // MARK: - Stato

    private struct Flake {
        let node: SKSpriteNode
        let radius: CGFloat
        /// 0 = lontano (piccolo, lento, trasparente) … 1 = vicino (grande, veloce, opaco).
        let depth: CGFloat
        let fallSpeed: CGFloat
        let swayAmplitude: CGFloat
        let swayFrequency: CGFloat
        let phase: CGFloat
        /// Velocità extra impressa dal cursore, si smorza nel tempo.
        var push: CGVector = .zero
    }

    private var flakes: [Flake] = []
    private let flakeTexture = SnowScene.makeFlakeTexture()
    private let screenOrigin: CGPoint

    private var lastUpdateTime: TimeInterval?
    private var elapsed: CGFloat = 0
    private var lastMouse: CGPoint?

    var density: Density {
        didSet { if density != oldValue { rebuildFlakes() } }
    }

    // MARK: - Init

    init(size: CGSize, screenOrigin: CGPoint, density: Density) {
        self.screenOrigin = screenOrigin
        self.density = density
        super.init(size: size)
        backgroundColor = .clear
        anchorPoint = .zero
        scaleMode = .resizeFill
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) non supportato")
    }

    override func didMove(to view: SKView) {
        rebuildFlakes()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        if !flakes.isEmpty && oldSize != size {
            rebuildFlakes()
        }
    }

    // MARK: - Fiocchi

    private func rebuildFlakes() {
        removeAllChildren()
        guard size.width > 0, size.height > 0 else {
            flakes = []
            return
        }
        let referenceArea: CGFloat = 1440 * 900
        let count = Int(density.flakesPerReferenceScreen * Double(size.width * size.height / referenceArea))
        flakes = (0..<max(count, 1)).map { _ in makeFlake(anywhere: true) }
    }

    /// Crea un fiocco. Con `anywhere` lo piazza in un punto a caso dello schermo
    /// (all'avvio), altrimenti appena sopra il bordo superiore (quando rinasce).
    private func makeFlake(anywhere: Bool) -> Flake {
        let depth = CGFloat.random(in: 0...1)
        let radius = 1.5 + depth * 3.5

        let node = SKSpriteNode(texture: flakeTexture)
        node.size = CGSize(width: radius * 2, height: radius * 2)
        node.alpha = 0.45 + depth * 0.5
        node.zPosition = depth
        node.position = CGPoint(
            x: .random(in: 0...size.width),
            y: anywhere ? .random(in: 0...size.height) : size.height + radius + .random(in: 0...40)
        )
        addChild(node)

        return Flake(
            node: node,
            radius: radius,
            depth: depth,
            fallSpeed: 22 + depth * 58,
            swayAmplitude: .random(in: 8...26),
            swayFrequency: .random(in: 0.3...0.9),
            phase: .random(in: 0...(2 * .pi))
        )
    }

    private func respawn(_ flake: inout Flake) {
        flake.node.position = CGPoint(
            x: .random(in: 0...size.width),
            y: size.height + flake.radius + .random(in: 0...40)
        )
        flake.push = .zero
    }

    // MARK: - Loop

    override func update(_ currentTime: TimeInterval) {
        // dt limitato: dopo una pausa o un rallentamento non vogliamo salti enormi.
        let dt = CGFloat(min(currentTime - (lastUpdateTime ?? currentTime), 1.0 / 20.0))
        lastUpdateTime = currentTime
        guard dt > 0 else { return }
        elapsed += dt

        // Vento globale che cambia lentamente.
        let wind = sin(elapsed * 0.11) * maxWind + sin(elapsed * 0.37) * maxWind * 0.3

        // Posizione e velocità del cursore in coordinate della scena.
        let global = NSEvent.mouseLocation
        let mouse = CGPoint(x: global.x - screenOrigin.x, y: global.y - screenOrigin.y)
        var mouseVelocity = CGVector.zero
        if let last = lastMouse {
            mouseVelocity = CGVector(dx: (mouse.x - last.x) / dt, dy: (mouse.y - last.y) / dt)
        }
        lastMouse = mouse

        let decay = CGFloat(exp(-Double(damping * dt)))
        let dragBlend = min(1, dt * 10)

        for i in flakes.indices {
            var flake = flakes[i]
            var p = flake.node.position

            // --- Interazione col cursore ---
            let dx = p.x - mouse.x
            let dy = p.y - mouse.y
            let distance = hypot(dx, dy)
            if distance < cursorRadius, distance > 0.001 {
                let falloff = 1 - distance / cursorRadius
                let strength = falloff * falloff

                // 1) spinta radiale: i fiocchi si scostano dal puntatore
                let repel = cursorRepel * strength * dt
                flake.push.dx += dx / distance * repel
                flake.push.dy += dy / distance * repel

                // 2) trascinamento: se muovi il mouse velocemente li "spazzi" via
                let targetDX = mouseVelocity.dx * cursorDrag
                let targetDY = mouseVelocity.dy * cursorDrag
                flake.push.dx += (targetDX - flake.push.dx) * strength * dragBlend
                flake.push.dy += (targetDY - flake.push.dy) * strength * dragBlend
            }
            flake.push.dx *= decay
            flake.push.dy *= decay

            // --- Movimento naturale ---
            let sway = cos(elapsed * flake.swayFrequency * 2 * .pi + flake.phase)
                * flake.swayAmplitude * flake.swayFrequency
            p.x += (wind * (0.4 + flake.depth) + sway + flake.push.dx) * dt
            p.y += (-flake.fallSpeed + flake.push.dy) * dt

            // Bordi laterali: chi esce da un lato rientra dall'altro.
            let margin: CGFloat = 20
            if p.x < -margin { p.x += size.width + margin * 2 }
            if p.x > size.width + margin { p.x -= size.width + margin * 2 }

            flake.node.position = p

            // Arrivato in fondo: rinasce in cima.
            if p.y < -flake.radius {
                respawn(&flake)
            }

            flakes[i] = flake
        }
    }

    // MARK: - Texture

    /// Un pallino bianco sfumato con un leggerissimo bordo grigio-azzurro,
    /// così la neve resta visibile anche sopra le finestre bianche.
    private static func makeFlakeTexture(diameter: CGFloat = 32) -> SKTexture {
        let size = NSSize(width: diameter, height: diameter)
        let image = NSImage(size: size, flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            let colors = [
                NSColor(white: 1, alpha: 1).cgColor,
                NSColor(white: 1, alpha: 0.9).cgColor,
                NSColor(calibratedRed: 0.72, green: 0.80, blue: 0.90, alpha: 0.45).cgColor,
                NSColor(calibratedRed: 0.72, green: 0.80, blue: 0.90, alpha: 0).cgColor,
            ] as CFArray
            let locations: [CGFloat] = [0, 0.45, 0.75, 1]
            guard let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors,
                locations: locations
            ) else { return false }
            let center = CGPoint(x: rect.midX, y: rect.midY)
            ctx.drawRadialGradient(
                gradient,
                startCenter: center, startRadius: 0,
                endCenter: center, endRadius: rect.width / 2,
                options: []
            )
            return true
        }
        return SKTexture(image: image)
    }
}
