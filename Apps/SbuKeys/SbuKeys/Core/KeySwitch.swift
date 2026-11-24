import SwiftUI

/// The switch the keyboard sounds like. Each has a down and an up sample per `KeyKind`.
nonisolated enum KeySwitch: String, CaseIterable, Identifiable, Sendable {
    case linear
    case tactile
    case clicky

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .linear: "Lineare"
        case .tactile: "Tattile"
        case .clicky: "Clic"
        }
    }

    /// The file name in `Sounds/`, without extension: `clicky-space-down`.
    func soundName(for kind: KeyKind, isDown: Bool) -> String {
        "\(rawValue)-\(kind.rawValue)-\(isDown ? "down" : "up")"
    }
}
