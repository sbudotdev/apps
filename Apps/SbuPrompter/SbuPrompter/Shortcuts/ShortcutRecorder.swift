import AppKit
import SbuKit
import SwiftUI

/// Shows a shortcut; click it and press new keys to change it, Esc to cancel.
struct ShortcutRecorder: View {
    let action: ShortcutAction
    @Environment(AppModel.self) private var model
    @State private var monitor: Any?
    @State private var rejected = false

    var body: some View {
        let isRecording = monitor != nil
        Button {
            isRecording ? stop() : start()
        } label: {
            Text(isRecording ? String(localized: "Premi i tasti…") : model.settings.combo(for: action).label)
                .monospaced()
                .frame(minWidth: 120)
        }
        .foregroundStyle(rejected ? SbuTheme.danger : SbuTheme.ink)
        .accessibilityHint(Text("Premi per registrare una nuova scorciatoia"))
        .onDisappear(perform: stop)
    }

    private func start() {
        model.suspendShortcuts(true)
        rejected = false
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 { // Esc
                stop()
                return nil
            }
            let combo = KeyCombo(keyCode: UInt32(event.keyCode), modifiers: Self.modifiers(event.modifierFlags),
                                 key: Self.keyName(event))
            guard combo.isValidGlobal else {
                rejected = true
                return nil
            }
            var shortcuts = model.settings.shortcuts
            // One action per combo: the old owner gets its default back.
            for (other, existing) in shortcuts where existing == combo && other != action {
                shortcuts[other] = other.defaultCombo == combo ? nil : other.defaultCombo
            }
            shortcuts[action] = combo
            model.settings.shortcuts = shortcuts
            stop()
            return nil
        }
    }

    private func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        model.suspendShortcuts(false)
    }

    private static func modifiers(_ flags: NSEvent.ModifierFlags) -> KeyCombo.Modifiers {
        var result: KeyCombo.Modifiers = []
        if flags.contains(.control) { result.insert(.control) }
        if flags.contains(.option) { result.insert(.option) }
        if flags.contains(.shift) { result.insert(.shift) }
        if flags.contains(.command) { result.insert(.command) }
        return result
    }

    private static func keyName(_ event: NSEvent) -> String {
        let special: [UInt16: String] = [49: "␣", 36: "↩", 48: "⇥", 51: "⌫", 117: "⌦", 123: "←", 124: "→", 125: "↓", 126: "↑",
                                         115: "↖", 119: "↘", 116: "⇞", 121: "⇟",
                                         122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6", 98: "F7", 100: "F8",
                                         101: "F9", 109: "F10", 103: "F11", 111: "F12"]
        if let name = special[event.keyCode] { return name }
        return event.charactersIgnoringModifiers?.uppercased() ?? "?"
    }
}
