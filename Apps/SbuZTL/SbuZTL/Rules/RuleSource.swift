import Foundation

/// Where a rule comes from.
nonisolated struct RuleSource: Sendable, Equatable {
    let title: String
    let url: URL?
    /// ISO date this source was last read by a person.
    let verified: String

    static let areaC = RuleSource(
        title: "Comune di Milano, DD 6517/2025", url: URL(string: "https://www.comune.milano.it/documents/d/guest/dd_6517_2025-file-primario-dd-6517-2025_timbrato-pdf?download=true"), verified: "2026-11-01")
    static let areaB = RuleSource(
        title: "Comune di Milano, DD 8390/2025", url: URL(string: "https://www.comune.milano.it/documents/d/guest/dd_8390_2025-file-primario-dd-8390-2025_timbrato?download=true"), verified: "2026-11-01")
    static let firenze = RuleSource(
        title: "Comune di Firenze, Mobilità, ZTL", url: URL(string: "https://mobilita.comune.fi.it/muoversi/muoversi/ztl.html"), verified: "2026-11-01")
    static let milanoData = RuleSource(
        title: "Comune di Milano, dataset ZTL e aree pedonali", url: URL(string: "https://dati.comune.milano.it"), verified: "2026-11-01")
}
