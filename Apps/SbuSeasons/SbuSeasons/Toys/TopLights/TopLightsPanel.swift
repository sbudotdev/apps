import AppKit

/// La finestra delle Luci in alto (SBU-229): una striscia trasparente appena sotto la barra dei menu, larga quanto lo
/// schermo, sopra le finestre delle app come gli effetti (`OverlayWindow`). I clic la attraversano sempre.
/// Senza `fullScreenAuxiliary`: sopra un'app a schermo intero non c'è.
final class TopLightsPanel: NSPanel {
    let view = TopLightsView()

    init() {
        super.init(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        isReleasedWhenClosed = false
        hidesOnDeactivate = false
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        contentView = view
    }

    override var canBecomeKey: Bool { false }
}
