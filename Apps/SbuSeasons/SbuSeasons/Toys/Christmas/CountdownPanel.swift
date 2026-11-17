import AppKit
import SwiftUI

/// Il conto alla rovescia per Natale: un pannellino sul desktop (dietro le finestre delle app, come un widget)
/// che si sposta trascinandolo e ricorda dove l'hai messo. Si accende dal menu ❄︎.
final class CountdownPanel: NSPanel {
    init() {
        super.init(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isMovableByWindowBackground = true
        isReleasedWhenClosed = false
        hidesOnDeactivate = false
        // Sopra le icone della scrivania, sotto le finestre delle app.
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        let host = DraggableHostingView(rootView: CountdownView())
        contentView = host
        setContentSize(host.fittingSize)
        // La prima volta in alto a sinistra; poi dove l'hai lasciato.
        if !setFrameUsingName(Self.autosaveName), let screen = NSScreen.main {
            setFrameTopLeftPoint(CGPoint(x: screen.visibleFrame.minX + Quaderno.space6, y: screen.visibleFrame.maxY - Quaderno.space6))
        }
        setFrameAutosaveName(Self.autosaveName)
    }

    private static let autosaveName = "countdown"

    override var canBecomeKey: Bool { false }
}

/// Il trascinamento sposta il pannello, anche al primo clic con l'app non attiva.
private final class DraggableHostingView<Content: View>: NSHostingView<Content> {
    override var mouseDownCanMoveWindow: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

/// Giorni, ore e minuti al 25 dicembre; il giorno di Natale gli auguri. Si ridisegna una volta al minuto.
struct CountdownView: View {
    var body: some View {
        TimelineView(.everyMinute) { context in
            VStack(alignment: .leading, spacing: Quaderno.space1) {
                if let left = ChristmasDates.countdown(from: context.date) {
                    Text("Natale tra")
                        .font(Quaderno.cartiglioFont)
                        .textCase(.uppercase)
                        .tracking(Quaderno.cartiglioSize * Quaderno.cartiglioTracking)
                        .foregroundStyle(Quaderno.inkMuted.color)
                    Text("\(left.day ?? 0) giorni")
                        .font(Quaderno.titleFont)
                        .foregroundStyle(Quaderno.ink.color)
                    HStack(spacing: Quaderno.space1) {
                        Text("\(left.hour ?? 0) ore")
                        Text(verbatim: "·").accessibilityHidden(true)
                        Text("\(left.minute ?? 0) minuti")
                    }
                    .monospacedDigit()
                    .foregroundStyle(Quaderno.ink.color)
                } else {
                    Text("Buon Natale!")
                        .font(Quaderno.titleFont)
                        .foregroundStyle(Quaderno.ink.color)
                }
            }
        }
        .padding(Quaderno.space4)
        .frame(width: Quaderno.gridCell * 9, alignment: .leading)
        .background(Quaderno.paper.color, in: RoundedRectangle(cornerRadius: Quaderno.space4))
        // VoiceOver legge tutto insieme: "Natale tra, 37 giorni, 2 ore, 44 minuti".
        .accessibilityElement(children: .combine)
    }
}
