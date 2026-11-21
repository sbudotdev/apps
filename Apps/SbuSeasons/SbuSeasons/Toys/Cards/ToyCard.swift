import AppKit
import SwiftUI

/// La scheda di un oggetto (SBU-178): un pannellino sopra l'oggetto, con i controlli nativi.
/// Il pupazzo ci sceglie taglie e vestiti, l'albero la decorazione da appendere, l'altezza e il taglio.
/// È un pannello "non attivante": prende i clic senza portare Sbu Seasons davanti; si chiude con la ✕, con Esc
/// o facendo clic altrove. Ce n'è uno solo: aprirne un altro sostituisce il contenuto.
final class ToyCard: NSPanel {
    static let shared = ToyCard()

    private init() {
        super.init(contentRect: .zero, styleMask: [.titled, .closable, .nonactivatingPanel, .utilityWindow],
                   backing: .buffered, defer: true)
        isReleasedWhenClosed = false
        hidesOnDeactivate = false
        becomesKeyOnlyIfNeeded = false
        // Sopra la finestra degli effetti (`OverlayWindow`, livello della barra di stato).
        level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 1)
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }

    /// Apre la scheda di `toy` appena sopra `point` (coordinate globali). Gli oggetti senza scheda non aprono niente.
    func show(for toy: Toy, at point: CGPoint) {
        let content: AnyView
        switch toy {
        case let snowman as Snowman:
            title = String(localized: "Pupazzo")
            content = AnyView(SnowmanCard(look: snowman.look) { [weak snowman] in snowman?.look = $0 })
        case let tree as ChristmasTree:
            title = String(localized: "Albero di Natale")
            content = AnyView(TreeCard(tree: tree,
                                       cut: { [weak self, weak tree] in
                                           tree?.cut()
                                           self?.close()
                                       }))
        default:
            return
        }
        let host = NSHostingView(rootView: content)
        contentView = host
        setContentSize(host.fittingSize)
        var origin = CGPoint(x: point.x - frame.width / 2, y: point.y + Quaderno.space1 * 2)
        // Tutta dentro lo schermo, sotto la barra dei menu.
        if let screen = NSScreen.screens.first(where: { $0.frame.contains(point) }) ?? NSScreen.main {
            let room = screen.visibleFrame
            origin.x = min(max(origin.x, room.minX), room.maxX - frame.width)
            origin.y = min(max(origin.y, room.minY), room.maxY - frame.height)
        }
        setFrameOrigin(origin)
        makeKeyAndOrderFront(nil)
    }

    override func cancelOperation(_ sender: Any?) { close() }

    /// Clic altrove: la scheda si chiude, come un popover.
    override func resignKey() {
        super.resignKey()
        close()
    }
}
