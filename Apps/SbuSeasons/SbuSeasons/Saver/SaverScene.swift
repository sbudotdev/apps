import AppKit
import SpriteKit

/// Quello che si vede nel salvaschermo: uno sfondo del borgo nel momento del giorno e, sopra, il suo effetto
/// (la stessa `SeasonScene` della scrivania, senza finestre né Dock: cade fino in fondo).
/// Sta nell'app per i test; nel salvaschermo la usa `SaverView`.
final class SaverScene: NSView {
    let wallpaper: Wallpaper
    private(set) var backdrop: CGImage?
    private(set) var scene: SeasonScene?
    private var skView: SKView?
    /// Fermato per sempre: niente più effetto finché non se ne crea un altro.
    private(set) var isStopped = false
    /// Dopo `stop()` per la notifica di fine: il salvaschermo vero chiude il processo.
    var onStop: (() -> Void)?

    /// macOS manda questa quando il salvaschermo finisce, anche quando non chiama `stopAnimation()`.
    static let willStop = Notification.Name("com.apple.screensaver.willstop")

    init(frame: CGRect, options: SaverOptions, moment: DayMoment, bundle: Bundle = .seasons,
         center: NotificationCenter = DistributedNotificationCenter.default()) {
        wallpaper = SaverOptions.pick(chosen: options.wallpaperID, previous: options.previousID)
        super.init(frame: frame)
        // Da macOS 14 legacyScreenSaver tiene vive le vecchie viste: senza questo l'effetto gira a schermo sbloccato.
        center.addObserver(self, selector: #selector(screenSaverWillStop), name: Self.willStop, object: nil)
        wantsLayer = true
        layer?.contentsGravity = .resizeAspectFill
        layer?.backgroundColor = NSColor.black.cgColor
        // Grande quanto lo schermo in pixel, non i 5000 del file: si legge e si tinge in un attimo.
        let pixels = Int(max(frame.width, frame.height) * (NSScreen.main?.backingScaleFactor ?? 2))
        if let url = wallpaper.url(for: frame.size, in: bundle) {
            backdrop = Thumbnail.make(url, moment: moment, longSide: max(pixels, 320))
            layer?.contents = backdrop
        }
        guard options.showsEffect else { return }
        let view = SKView(frame: bounds)
        view.allowsTransparency = true
        view.autoresizingMask = [.width, .height]
        let scene = SeasonScene(size: frame.size, screenOrigin: .zero, season: Seasons.named(wallpaper.effect))
        view.presentScene(scene)
        addSubview(view)
        skView = view
        self.scene = scene
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) non supportato")
    }

    /// Un fotogramma: lo chiama il salvaschermo (`animateOneFrame`).
    func step(at time: TimeInterval) {
        scene?.step(at: time)
    }

    /// A batteria e con Riduci movimento meno fotogrammi, come sulla scrivania.
    func setEnergy(onBattery: Bool, reduceMotion: Bool) {
        scene?.reduceMotion = reduceMotion
        skView?.preferredFramesPerSecond = Tuning.framesPerSecond(onBattery: onBattery, reduceMotion: reduceMotion)
    }

    func setPaused(_ paused: Bool) {
        skView?.isPaused = paused
    }

    /// Ferma e butta l'effetto: nessun fotogramma in più, anche se la vista resta viva.
    func stop() {
        isStopped = true
        skView?.isPaused = true
        skView?.presentScene(nil)
        skView?.removeFromSuperview()
        skView = nil
        scene = nil
    }

    @objc private func screenSaverWillStop(_ notification: Notification) {
        stop()
        onStop?()
    }
}
