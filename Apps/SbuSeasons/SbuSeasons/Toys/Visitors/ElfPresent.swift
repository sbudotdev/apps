import CoreGraphics

/// Che cosa c'è nel regalo del trenino (SBU-178): una decorazione nuova per un albero, un vestito per un pupazzo,
/// o, se sullo schermo non c'è né l'uno né l'altro, un albero da decorare. Tutto si può avere anche senza regalo:
/// il regalo è una sorpresa, non uno sblocco.
nonisolated enum ElfPresent: Equatable, Sendable {
    case decoration(DecorationKind)
    case hat(SnowmanLook.Hat)
    case scarf(SnowmanLook.Scarf)
    case buttons
    case tree

    /// Le sorprese possibili per quello che c'è sullo schermo; `roll` in 0..<1 sceglie.
    static func pick(hasTree: Bool, snowman: SnowmanLook?, roll: Double) -> ElfPresent {
        var choices: [ElfPresent] = []
        if hasTree { choices += DecorationKind.allCases.map { .decoration($0) } }
        if let look = snowman {
            if look.hat == .none { choices += [.hat(.topHat), .hat(.beanie)] }
            if look.scarf == .none { choices += [.scarf(.red), .scarf(.green)] }
            if !look.buttons { choices.append(.buttons) }
        }
        guard !choices.isEmpty else { return .tree }
        return choices[min(Int(roll * Double(choices.count)), choices.count - 1)]
    }
}
