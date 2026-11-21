import CoreGraphics

/// Che cosa si appende all'albero. La stella e l'angelo vanno sempre in cima: uno solo per albero.
nonisolated enum DecorationKind: String, Codable, CaseIterable, Sendable {
    case bauble, lights, candyCane, star, angel

    /// Va in cima, al posto di quello che c'era.
    var isTopper: Bool { self == .star || self == .angel }

    var title: String {
        switch self {
        case .bauble: String(localized: "Palline")
        case .lights: String(localized: "Luci")
        case .candyCane: String(localized: "Bastoncini")
        case .star: String(localized: "Stella")
        case .angel: String(localized: "Angelo")
        }
    }

    /// Una sola, per il titolo della sua parte nella scheda.
    var name: String {
        switch self {
        case .bauble: String(localized: "Pallina")
        case .lights: String(localized: "Filo di luci")
        case .candyCane: String(localized: "Bastoncino")
        case .star: String(localized: "Stella")
        case .angel: String(localized: "Angelo")
        }
    }

    /// Il lato del disegno a grandezza 1 (pt): serve anche per capire se il cursore ci è sopra.
    var side: CGFloat {
        switch self {
        case .bauble: 7
        case .lights: 22
        case .candyCane: 10
        case .star: 13
        case .angel: 14
        }
    }
}

/// Una decorazione appesa: dove sta rispetto ai piedi dell'albero (albero a grandezza 1), quanto è grande e girata.
nonisolated struct Decoration: Codable, Equatable, Sendable {
    var kind: DecorationKind
    var position: CGPoint
    var scale: CGFloat = 1
    /// Radianti, in senso antiorario come `zRotation`.
    var rotation: CGFloat = 0
    /// Il colore delle palline, a turno (indice in `ChristmasTree.colors`).
    var color = 0

    /// Il cursore è sopra? Un cerchio largo quanto il disegno, almeno 6 pt di raggio per prenderle anche piccole.
    func contains(_ point: CGPoint) -> Bool {
        hypot(point.x - position.x, point.y - position.y) <= max(kind.side * scale / 2, 6)
    }
}
