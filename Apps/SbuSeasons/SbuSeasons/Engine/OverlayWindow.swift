import AppKit
import SpriteKit

/// Finestra trasparente, senza bordi, che copre un intero schermo e sta sopra
/// alle altre finestre. I click la attraversano (`ignoresMouseEvents`), quindi
/// le app sotto continuano a funzionare normalmente; solo sopra un oggetto con cui giocare
/// la finestra prende il mouse (README, "Clic sugli oggetti").
///
/// È un pannello "non attivante": cliccare un oggetto non porta l'app davanti e non toglie
/// la tastiera all'app che stai usando.
///
/// La `SKView` disegna, ma la scena la muove un display link della finestra, che segue il suo schermo.
/// Con due schermi a frequenze diverse (144 e 60 Hz) SpriteKit chiamava `update` solo sulla scena
/// dello schermo più lento e sull'altro la neve si fermava o andava lentissima (SBU-19).
final class OverlayWindow: NSPanel {
    private let skView: SKView
    /// La scena: i giochi d'inverno del menu la chiamano direttamente (`SeasonScene`, `Toys/WinterPlay/WinterPlay.swift`).
    let scene: SeasonScene
    private var displayLink: CADisplayLink?
    private var takesMouse = false
    private var behindWindows = false
    /// Batteria e Riduci movimento dell'ultima volta, e «120 fps» come era allora: se cambia, si ricalcola.
    private var energy = (onBattery: false, reduceMotion: false)
    private var highRate = false
    /// Quanti fotogrammi al secondo fa questo schermo (120 sui ProMotion).
    private let maxFPS: Int
    /// L'effetto gira (false = spento dal menu, schermo coperto da un'app a schermo intero o display che dorme).
    private var running: Bool?

    init(screen: NSScreen) {
        let frame = screen.frame
        maxFPS = screen.maximumFramesPerSecond
        screenID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID

        skView = OverlaySKView(frame: NSRect(origin: .zero, size: frame.size))
        scene = SeasonScene(size: frame.size, screenOrigin: frame.origin, season: Settings.shared.season)

        super.init(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        isReleasedWhenClosed = false
        hidesOnDeactivate = false   // un pannello di norma sparisce quando l'app non è davanti

        level = Self.level(behindWindows: false)

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

    /// Sopra: sopra le finestre normali e sopra il Dock, sotto i menu a tendina.
    /// Dietro: appena sopra lo sfondo e le icone della scrivania, sotto tutte le finestre delle app.
    static func level(behindWindows: Bool) -> NSWindow.Level {
        behindWindows ? NSWindow.Level(Int(CGWindowLevelForKey(.desktopIconWindow)) + 1) : .statusBar
    }

    @objc private func step(_ link: CADisplayLink) {
        // Dal menu ❄︎ o dalle Impostazioni: confrontare un Bool a ogni fotogramma costa niente.
        if Settings.shared.values.behindWindows != behindWindows {
            behindWindows.toggle()
            level = Self.level(behindWindows: behindWindows)
        }
        if Settings.shared.values.highFrameRate != highRate { setEnergy(onBattery: energy.onBattery, reduceMotion: energy.reduceMotion) }
        scene.step(at: link.targetTimestamp)
        // Il mouse si prende solo sopra un oggetto: la scena lo ricontrolla a ogni fotogramma.
        // Lo stato si tiene qui: leggere `ignoresMouseEvents` a ogni fotogramma costava CPU.
        if scene.wantsMouse != takesMouse {
            takesMouse = scene.wantsMouse
            ignoresMouseEvents = !takesMouse
        }
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
    func clearSnowballs() { scene.clearSnowballs() }
    func shakeGlobe() { scene.shakeGlobe() }
    /// Lo schermo di questa finestra, per la pausa automatica.
    let screenID: CGDirectDisplayID?
    /// Il tempo simulato della neve su questo schermo.
    var elapsed: CGFloat { scene.elapsed }
    func setSeason(_ season: any Season) { scene.setSeason(season) }
    func add(_ toy: Toy) { scene.add(toy) }
    var hasDock: Bool { scene.dockLedge != nil }
    var hasCableCar: Bool { scene.hasCableCar }
    func windowsShaken(_ ids: Set<CGWindowID>) { scene.windowsShaken(ids) }

    /// Batteria e "Riduci movimento": in entrambi i casi meno fotogrammi; con Riduci movimento anche meno movimento.
    /// Con «120 fps sugli schermi ProMotion» acceso (Impostazioni → Meteo), a corrente e senza Riduci movimento, 120.
    func setEnergy(onBattery: Bool, reduceMotion: Bool) {
        energy = (onBattery, reduceMotion)
        highRate = Settings.shared.values.highFrameRate
        scene.reduceMotion = reduceMotion
        let fps = Tuning.framesPerSecond(onBattery: onBattery, reduceMotion: reduceMotion, highRate: highRate, maxFPS: maxFPS)
        skView.preferredFramesPerSecond = fps
        displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: Float(fps), maximum: Float(fps), preferred: Float(fps))
    }

    /// Accende o spegne l'effetto su questo schermo. Lo stesso stato di nuovo non fa niente: `AppDelegate` lo richiama
    /// a ogni lettura delle finestre (pausa automatica, SBU-177).
    func setSnowing(_ snowing: Bool) {
        guard snowing != running else { return }
        running = snowing
        skView.isPaused = !snowing
        displayLink?.isPaused = !snowing
        if !snowing {
            scene.dropHeld()
            takesMouse = false
            ignoresMouseEvents = true
        }
        if snowing {
            orderFrontRegardless()
        } else {
            orderOut(nil)
        }
    }
}

/// La `SKView` prende anche il primo clic: la finestra non diventa mai attiva, e senza questo
/// il clic su un oggetto servirebbe solo ad "attivarla" e andrebbe perso.
private final class OverlaySKView: SKView {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}
