import AppKit
import SpriteKit

/// Finestra trasparente, senza bordi, che copre un intero schermo e sta sopra
/// alle altre finestre. I click la attraversano (`ignoresMouseEvents`), quindi
/// le app sotto continuano a funzionare normalmente.
///
/// La `SKView` disegna, ma la scena la muove un display link della finestra, che segue il suo schermo.
/// Con due schermi a frequenze diverse (144 e 60 Hz) SpriteKit chiamava `update` solo sulla scena
/// dello schermo più lento e sull'altro la neve si fermava o andava lentissima (SBU-19).
final class OverlayWindow: NSWindow {
    private let skView: SKView
    private let scene: SeasonScene
    private var displayLink: CADisplayLink?

    init(screen: NSScreen) {
        let frame = screen.frame

        skView = SKView(frame: NSRect(origin: .zero, size: frame.size))
        scene = SeasonScene(size: frame.size, screenOrigin: frame.origin, season: Settings.shared.season)

        super.init(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        isReleasedWhenClosed = false

        // Sopra le finestre normali e sopra il Dock, sotto i menu a tendina.
        level = .statusBar

        // Visibile in tutte le Scrivanie (Spaces) e anche sopra le app a schermo intero.
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]

        skView.allowsTransparency = true
        skView.ignoresSiblingOrder = true
        contentView = skView
        skView.presentScene(scene)

        setFrame(frame, display: true)
        let link = skView.displayLink(target: self, selector: #selector(step))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    @objc private func step(_ link: CADisplayLink) {
        scene.step(at: link.targetTimestamp)
    }

    override func close() {
        displayLink?.invalidate()   // il display link tiene viva la finestra
        displayLink = nil
        super.close()
    }

    // Una finestra borderless di norma viene "spinta" sotto la barra dei menu:
    // qui la lasciamo esattamente dove la mettiamo, così la neve copre tutto lo schermo.
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        frameRect
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func updateWindows(_ edges: [WindowEdge], dock: CGRect?) {
        // La zona libera si rilegge ogni volta: la barra dei menu può nascondersi o riapparire.
        let ceiling = (screen?.visibleFrame.maxY ?? frame.maxY) - frame.minY
        scene.updateWindows(edges, dock: dock, ceiling: ceiling)
    }
    func meltAll() { scene.meltAll() }
    /// Il tempo simulato della neve su questo schermo.
    var elapsed: CGFloat { scene.elapsed }
    func setSeason(_ season: any Season) { scene.setSeason(season) }

    func setOnBattery(_ onBattery: Bool) {
        let fps = Tuning.framesPerSecond(onBattery: onBattery)
        skView.preferredFramesPerSecond = fps
        displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: Float(fps), maximum: Float(fps), preferred: Float(fps))
    }

    func setSnowing(_ snowing: Bool) {
        skView.isPaused = !snowing
        displayLink?.isPaused = !snowing
        if snowing {
            orderFrontRegardless()
        } else {
            orderOut(nil)
        }
    }
}
