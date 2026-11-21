import Foundation

/// The name shown for a cue: its title, or "Sezione 2" for an untitled break.
enum CueTitle {
    static func text(_ title: String?, index: Int) -> String {
        if let title, !title.isEmpty { return title }
        return String(localized: "Sezione \(index + 1)")
    }
}
