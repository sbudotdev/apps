import CoreGraphics

/// I visitatori che passano da soli (SBU-178).
nonisolated enum VisitorKind: CaseIterable, Sendable {
    case yeti, train, elves

    /// La chiave in UserDefaults di "passa da solo" (Impostazioni → Visitatori), acceso all'inizio.
    var autoKey: String {
        switch self {
        case .yeti: "yetiVisits"
        case .train: "trainVisits"
        case .elves: "elfVisits"
        }
    }

    var interval: ClosedRange<CGFloat> {
        switch self {
        case .yeti: Tuning.yetiInterval
        case .train: Tuning.trainInterval
        case .elves: Tuning.elvesInterval
        }
    }
}

/// Come è uscito un visitatore da uno schermo: da che parte, con che cosa in spalla, se scappava.
nonisolated struct VisitorExit: Equatable, Sendable {
    var heading: CGFloat
    var carrying: SnowmanLook?
    var fled = false
}
