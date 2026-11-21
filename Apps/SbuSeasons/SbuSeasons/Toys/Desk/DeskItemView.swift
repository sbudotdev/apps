import AppKit

/// Una decorazione della scrivania (SBU-187): la disegna e la muove. Trascinandola si sposta (le luci: da un'estremità
/// si sposta solo quella); pizzico o rotella la ingrandiscono, due dita o ⇧ e la rotella la girano;
/// il clic destro (o ⌃ clic) la manda a qualcuno o la toglie.
final class DeskItemView: NSView {
    var item: DeskItem { didSet { needsDisplay = true } }
    /// Il tempo delle fiamme e delle lampadine (0 = ferme).
    var phase: CGFloat = 0 { didSet { if item.kind.flickers { needsDisplay = true } } }
    /// L'angolo in basso a sinistra del suo schermo, in coordinate globali.
    var screenOrigin: CGPoint = .zero
    var onChange: ((DeskItem) -> Void)?
    var onRemove: (() -> Void)?
    /// Fine di un trascinamento: la decorazione può essere passata su un altro schermo.
    var onDrop: (() -> Void)?

    private var last: CGPoint?
    private var grabbedEnd: Int?

    init(item: DeskItem) {
        self.item = item
        super.init(frame: CGRect(origin: .zero, size: item.frame.size))
        setAccessibilityElement(true)
        setAccessibilityRole(.image)
        setAccessibilityLabel(item.kind.title)
        // Con VoiceOver si toglie senza clic destro (QA SBU-188).
        setAccessibilityCustomActions([NSAccessibilityCustomAction(name: String(localized: "Togli")) { [weak self] in
            self?.onRemove?()
            return true
        }, NSAccessibilityCustomAction(name: String(localized: "Manda…")) { [weak self] in
            self?.sendItem()
            return true
        }])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) non supportato") }

    override var isFlipped: Bool { false }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        DeskArt.draw(item, phase: phase)
    }

    /// Il cursore, in coordinate del suo schermo.
    private var pointer: CGPoint {
        let p = NSEvent.mouseLocation
        return CGPoint(x: p.x - screenOrigin.x, y: p.y - screenOrigin.y)
    }

    override func mouseDown(with event: NSEvent) {
        if event.modifierFlags.contains(.control) { return rightMouseDown(with: event) }
        last = pointer
        grabbedEnd = item.kind == .lights ? item.end(near: pointer) : nil
    }

    override func mouseDragged(with event: NSEvent) {
        guard let last else { return }
        let now = pointer
        if let grabbedEnd {
            item.moveEnd(grabbedEnd, to: now)
        } else {
            item.move(by: CGVector(dx: now.x - last.x, dy: now.y - last.y))
        }
        self.last = now
        onChange?(item)
    }

    override func mouseUp(with event: NSEvent) {
        guard last != nil else { return }
        last = nil
        grabbedEnd = nil
        onDrop?()
    }

    override func magnify(with event: NSEvent) { change { $0.resize(by: 1 + event.magnification) } }
    override func rotate(with event: NSEvent) { change { $0.turn(by: CGFloat(event.rotation) * .pi / 180) } }

    override func scrollWheel(with event: NSEvent) {
        let step: CGFloat = event.hasPreciseScrollingDeltas ? 1 : 10
        if event.modifierFlags.contains(.shift) || event.modifierFlags.contains(.option) {
            let raw = event.scrollingDeltaY != 0 ? event.scrollingDeltaY : event.scrollingDeltaX
            change { $0.turn(by: raw * step * .pi / 180) }
        } else {
            change { $0.resize(by: exp(event.scrollingDeltaY * step * Tuning.scrollResize)) }
        }
    }

    /// Le luci non si girano: le girano le loro estremità.
    private func change(_ edit: (inout DeskItem) -> Void) {
        var changed = item
        edit(&changed)
        if item.kind == .lights { changed.rotation = 0 }
        guard changed != item else { return }
        item = changed
        onChange?(item)
    }

    override func rightMouseDown(with event: NSEvent) {
        let menu = NSMenu()
        let send = NSMenuItem(title: String(localized: "Manda…"), action: #selector(sendItem), keyEquivalent: "")
        send.target = self
        menu.addItem(send)
        let remove = NSMenuItem(title: String(localized: "Togli"), action: #selector(removeItem), keyEquivalent: "")
        remove.target = self
        menu.addItem(remove)
        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }

    @objc private func removeItem() { onRemove?() }

    /// La decorazione diventa un file da mandare (SBU-200).
    @objc private func sendItem() { ToySharing.shared.share(.decoration(item), from: self) }
}
