import Foundation

/// A covered municipality.
nonisolated enum City: String, Codable, CaseIterable, Sendable, Identifiable {
    case milano
    case firenze
    case bologna
    case roma
    case torino

    var id: String { rawValue }

    /// Names are the cities' own: not translated in the zone list.
    var name: String {
        switch self {
        case .milano: "Milano"
        case .firenze: "Firenze"
        case .bologna: "Bologna"
        case .roma: "Roma"
        case .torino: "Torino"
        }
    }

    var source: URL? {
        switch self {
        case .milano: URL(string: "https://www.comune.milano.it/aree-tematiche/mobilita")
        case .firenze: URL(string: "https://mobilita.comune.fi.it/muoversi/muoversi/ztl.html")
        case .bologna: URL(string: "https://opendata.comune.bologna.it/explore/dataset/zona-a-traffico-limitato/")
        case .roma: URL(string: "https://romamobilita.it/muoversi-a-roma/ztl-in-centro/")
        case .torino: URL(string: "https://www.comune.torino.it/schede-informative/ztl-centrale")
        }
    }

    /// Zones the sources describe but whose perimeter isn't bundled: a route or an empty point here proves nothing.
    var missingPerimeters: LocalizedStringResource? {
        switch self {
        case .milano, .firenze: nil
        case .bologna: "Non ho i perimetri di Università, San Francesco-Pratello e Moline-Capo di Lucca, attive 24 ore su 24."
        case .roma: "Non ho i perimetri di Tridente e Testaccio: possono valere regole che non vedo."
        case .torino: "Non ho i perimetri delle zone Pedonale, Romana, Valentino e delle corsie riservate."
        }
    }
}
