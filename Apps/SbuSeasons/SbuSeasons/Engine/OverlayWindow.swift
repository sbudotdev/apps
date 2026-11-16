import AppKit
import MetalKit
import SpriteKit

/// Finestra trasparente, senza bordi, che copre un intero schermo e sta sopra
/// alle altre finestre. I click la attraversano (`ignoresMouseEvents`), quindi
/// le app sotto continuano a funzionare normalmente.
///
/// Niente `SKView`: SpriteKit muove tutte le `SKView` del processo con un solo display link,
/// legato a uno schermo. Con due monitor a frequenze diverse (144 e 60 Hz) la vista sull'altro
/// schermo restava quasi senza frame e la neve lì andava lentissima (MGS-636).
/// Qui ogni finestra ha il suo display link, che segue il suo schermo, e disegna la scena con `SKRenderer`.
final class OverlayWindow: NSWindow {
    private let metalView: MTKView
    private let renderer: SKRenderer
    private let commandQueue: MTLCommandQueue
    private let scene: SeasonScene
    private var displayLink: CADisplayLink?

    /// nil se manca la GPU: `MTLCreateSystemDefaultDevice()` può dare nil su un Mac senza schermo attivo
    /// (un Mac Studio con i monitor spenti). Niente neve su quello schermo fino al prossimo cambio di schermi (MGS-686).
    init?(screen: NSScreen, device: (any MTLDevice)? = MTLCreateSystemDefaultDevice()) {
        guard let device, let commandQueue = device.makeCommandQueue() else { return nil }
        let frame = screen.frame

        metalView = MTKView(frame: NSRect(origin: .zero, size: frame.size), device: device)
        self.commandQueue = commandQueue
        renderer = SKRenderer(device: device)
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

        metalView.layer?.isOpaque = false
        metalView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        // Disegna solo quando lo chiede il nostro display link.
        metalView.isPaused = true
        metalView.enableSetNeedsDisplay = false
        contentView = metalView

        // La scena è in punti, il disegno in pixel: `.fill` la scala sullo schermo (Retina compreso).
        scene.scaleMode = .fill
        renderer.scene = scene
        renderer.ignoresSiblingOrder = true

        setFrame(frame, display: true)
        let link = metalView.displayLink(target: self, selector: #selector(drawFrame))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    @objc private func drawFrame(_ link: CADisplayLink) {
        renderer.update(atTime: link.timestamp)
        guard let pass = metalView.currentRenderPassDescriptor, let drawable = metalView.currentDrawable,
              let commands = commandQueue.makeCommandBuffer() else { return }
        renderer.render(withViewport: CGRect(origin: .zero, size: metalView.drawableSize),
                        commandBuffer: commands, renderPassDescriptor: pass)
        commands.present(drawable)
        commands.commit()
    }

    override func close() {
        displayLink?.invalidate()   // il display link tiene viva la finestra
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
    func setSeason(_ season: any Season) { scene.setSeason(season) }

    func setOnBattery(_ onBattery: Bool) {
        let fps = Float(Tuning.framesPerSecond(onBattery: onBattery))
        displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: fps, maximum: fps, preferred: fps)
    }

    func setSnowing(_ snowing: Bool) {
        displayLink?.isPaused = !snowing
        if snowing {
            orderFrontRegardless()
        } else {
            orderOut(nil)
        }
    }
}
