/// Which sample a key plays: most keys share one, the long keys sound deeper.
nonisolated enum KeyKind: String, CaseIterable, Sendable {
    case key
    case space
    /// Return, Enter, Delete, Forward Delete and Tab: the wide keys on the right and left.
    case enter

    /// Virtual key codes from `HIToolbox/Events.h`, so the core stays free of Carbon.
    init(keyCode: Int) {
        switch keyCode {
        case 49: self = .space
        case 36, 76, 51, 117, 48: self = .enter
        default: self = .key
        }
    }
}
