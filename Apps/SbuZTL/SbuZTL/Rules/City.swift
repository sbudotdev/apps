import Foundation

/// A covered municipality.
nonisolated enum City: String, Codable, CaseIterable, Sendable, Identifiable {
    case milano
    case firenze

    var id: String { rawValue }

    /// Names are the cities' own: not translated in the zone list.
    var name: String {
        switch self {
        case .milano: "Milano"
        case .firenze: "Firenze"
        }
    }

    var source: URL? {
        switch self {
        case .milano: URL(string: "https://www.comune.milano.it/aree-tematiche/mobilita")
        case .firenze: URL(string: "https://mobilita.comune.fi.it/muoversi/muoversi/ztl.html")
        }
    }
}
