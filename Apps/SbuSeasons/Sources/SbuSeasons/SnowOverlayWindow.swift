import AppKit
import SpriteKit

/// Finestra trasparente, senza bordi, che copre un intero schermo e sta sopra
/// alle altre finestre. I click la attraversano (`ignoresMouseEvents`), quindi
/// le app sotto continuano a funzionare normalmente.
final class SnowOverlayWindow: NSWindow {
    private let skView: SKView
    private let scene: SnowScene

    init(screen: NSScreen) {
        let frame = screen.frame

        skView = SKView(frame: NSRect(origin: .zero, size: frame.size))
        scene = SnowScene(size: frame.size, screenOrigin: frame.origin)

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
        skView.preferredFramesPerSecond = 60
        contentView = skView
        skView.presentScene(scene)

        setFrame(frame, display: true)
    }

    // Una finestra borderless di norma viene "spinta" sotto la barra dei menu:
    // qui la lasciamo esattamente dove la mettiamo, così la neve copre tutto lo schermo.
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        frameRect
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func updateWindows(_ edges: [WindowEdge], dock: CGRect?) { scene.updateWindows(edges, dock: dock) }
    func meltAll() { scene.meltAll() }

    func setSnowing(_ snowing: Bool) {
        skView.isPaused = !snowing
        if snowing {
            orderFrontRegardless()
        } else {
            orderOut(nil)
        }
    }
}
