import AppKit

/// Il pannello di una decorazione della scrivania (SBU-187): sul desktop, sopra le icone e dietro le finestre delle app,
/// come il conto alla rovescia (`CountdownPanel`). Grande quanto la decorazione: altrove i clic arrivano alla scrivania.
final class DeskPanel: NSPanel {
    let view: DeskItemView

    init(item: DeskItem, screenOrigin: CGPoint) {
        view = DeskItemView(item: item)
        view.screenOrigin = screenOrigin
        super.init(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isReleasedWhenClosed = false
        hidesOnDeactivate = false
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        contentView = view
        place()
    }

    override var canBecomeKey: Bool { false }

    /// Rimette il pannello attorno alla decorazione (dopo uno spostamento, un pizzico, una rotazione).
    func place() {
        let f = view.item.frame
        setFrame(CGRect(x: f.minX + view.screenOrigin.x, y: f.minY + view.screenOrigin.y, width: f.width, height: f.height),
                 display: true)
        view.frame = CGRect(origin: .zero, size: f.size)
    }
}
