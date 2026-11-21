/// The actions that have a global shortcut (spec point 11).
nonisolated enum ShortcutAction: String, CaseIterable, Codable, Sendable {
    case togglePlay, faster, slower, previousCue, nextCue, returnFromCue, toggleVisibility

    var command: PrompterCommand {
        switch self {
        case .togglePlay: .togglePlay
        case .faster: .faster
        case .slower: .slower
        case .previousCue: .previousCue
        case .nextCue: .nextCue
        case .returnFromCue: .returnFromCue
        case .toggleVisibility: .toggleVisibility
        }
    }

    /// ⌃⌥ plus a key, out of the way of the shortcuts apps usually take.
    var defaultCombo: KeyCombo {
        let both: KeyCombo.Modifiers = [.control, .option]
        return switch self {
        case .togglePlay: KeyCombo(keyCode: 49, modifiers: both, key: "␣")
        case .faster: KeyCombo(keyCode: 126, modifiers: both, key: "↑")
        case .slower: KeyCombo(keyCode: 125, modifiers: both, key: "↓")
        case .previousCue: KeyCombo(keyCode: 123, modifiers: both, key: "←")
        case .nextCue: KeyCombo(keyCode: 124, modifiers: both, key: "→")
        case .returnFromCue: KeyCombo(keyCode: 15, modifiers: both, key: "R")
        case .toggleVisibility: KeyCombo(keyCode: 4, modifiers: both, key: "H")
        }
    }
}
