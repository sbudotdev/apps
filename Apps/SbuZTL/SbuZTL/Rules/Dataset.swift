import Foundation

/// An open dataset the app bundles, cited as its licence asks. Titles and licences are the publishers' own words.
nonisolated struct Dataset: Sendable, Identifiable {
    let entity: String
    let title: String
    let licence: String
    let url: URL
    let city: City

    var id: String { url.absoluteString }

    static func all(in city: City) -> [Dataset] {
        all.filter { $0.city == city }
    }
}
