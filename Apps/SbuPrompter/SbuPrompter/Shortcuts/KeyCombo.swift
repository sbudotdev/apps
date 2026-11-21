/// A global shortcut: a key plus modifiers, stored as Carbon key code and the key's name as shown.
nonisolated struct KeyCombo: Codable, Hashable, Sendable {
    struct Modifiers: OptionSet, Codable, Hashable, Sendable {
        let rawValue: Int
        static let control = Modifiers(rawValue: 1 << 0)
        static let option = Modifiers(rawValue: 1 << 1)
        static let shift = Modifiers(rawValue: 1 << 2)
        static let command = Modifiers(rawValue: 1 << 3)
    }

    var keyCode: UInt32
    var modifiers: Modifiers
    /// The key as printed on the keyboard ("A", "Spazio", "→").
    var key: String

    var label: String {
        var text = ""
        if modifiers.contains(.control) { text += "⌃" }
        if modifiers.contains(.option) { text += "⌥" }
        if modifiers.contains(.shift) { text += "⇧" }
        if modifiers.contains(.command) { text += "⌘" }
        return text + key
    }

    /// Shift alone would steal ordinary typing from every app.
    var isValidGlobal: Bool {
        !modifiers.intersection([.control, .option, .command]).isEmpty
    }
}
