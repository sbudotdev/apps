import AppKit
import ScreenSaver
import SwiftUI

/// Il salvaschermo di Sbu Seasons (`NSPrincipalClass` in project.yml). Mostra `SaverScene` e le sue opzioni.
/// Non lo avvia mai l'app: lo sceglie l'utente in Impostazioni di Sistema → Salvaschermo.
@objc(SbuSeasonsSaverView)
final class SaverView: ScreenSaverView {
    private let defaults = ScreenSaverDefaults(forModuleWithName: Bundle.seasons.bundleIdentifier ?? "dev.sbu.SbuSeasons.Saver")
    private var content: SaverScene?
    private lazy var sheet = makeSheet()

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        build()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) non supportato")
    }

    /// Ogni volta uno sfondo nuovo (se non ne è scelto uno), nel momento di adesso.
    private func build() {
        content?.removeFromSuperview()
        guard let defaults else { return }
        var options = SaverOptions(defaults: defaults)
        let scene = SaverScene(frame: bounds, options: options, moment: DayMoment.at(.now))
        scene.autoresizingMask = [.width, .height]
        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        let fps = Tuning.framesPerSecond(onBattery: isOnBattery(), reduceMotion: reduceMotion)
        scene.setEnergy(onBattery: isOnBattery(), reduceMotion: reduceMotion)
        animationTimeInterval = 1 / Double(fps)
        addSubview(scene)
        content = scene
        if !isPreview {
            options.previousID = scene.wallpaper.id
            options.save(to: defaults)
        }
    }

    override func startAnimation() {
        super.startAnimation()
        content?.setPaused(false)
    }

    override func stopAnimation() {
        super.stopAnimation()
        content?.setPaused(true)
    }

    override func animateOneFrame() {
        content?.step(at: CACurrentMediaTime())
    }

    override var hasConfigureSheet: Bool { true }
    override var configureSheet: NSWindow? { sheet }

    private func makeSheet() -> NSWindow {
        let window = NSWindow(contentRect: .zero, styleMask: [.titled], backing: .buffered, defer: true)
        let initial = defaults.map(SaverOptions.init(defaults:))
        window.contentViewController = NSHostingController(rootView: SaverOptionsView(
            wallpaperID: initial?.wallpaperID, showsEffect: initial?.showsEffect ?? true
        ) { [weak self, weak window] wallpaperID, showsEffect in
            guard let self, let window else { return }
            if let defaults = self.defaults {
                var options = SaverOptions(defaults: defaults)
                options.wallpaperID = wallpaperID
                options.showsEffect = showsEffect
                options.save(to: defaults)
            }
            self.build()
            window.sheetParent?.endSheet(window)
        })
        return window
    }
}
