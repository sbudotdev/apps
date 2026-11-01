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
    static let romaZtl = RuleSource(
        title: "Roma Servizi per la Mobilità, ZTL in Centro", url: URL(string: "https://romamobilita.it/muoversi-a-roma/ztl-in-centro/"), verified: "2026-11-01")
    static let romaFasciaVerde = RuleSource(
        title: "Roma Servizi per la Mobilità, ZTL Fascia Verde", url: URL(string: "https://romamobilita.it/servizi-al-pubblico/ztl-fascia-verde/"), verified: "2026-11-01")
    static let torinoCentrale = RuleSource(
        title: "Comune di Torino, ZTL Centrale", url: URL(string: "https://www.comune.torino.it/schede-informative/ztl-centrale"), verified: "2026-11-01")
    static let bolognaZtl = RuleSource(
        title: "Comune di Bologna, ZTL ambientale, comunicato 2023", url: URL(string: "https://www.comune.bologna.it/novita/comunicati-stampa/ztl-ambientale-dal-primo-gennaio-2024-i-possessori-di-veicoli-euro-4-diesel-non-potranno-piu"), verified: "2026-11-01")
    static let bolognaData = RuleSource(
        title: "Comune di Bologna, dataset Zona a traffico limitato", url: URL(string: "https://opendata.comune.bologna.it/explore/dataset/zona-a-traffico-limitato/"), verified: "2026-11-01")
    static let milanoData = RuleSource(
        title: "Comune di Milano, dataset ZTL e aree pedonali", url: URL(string: "https://dati.comune.milano.it"), verified: "2026-11-01")
}
