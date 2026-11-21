import Foundation

/// Nel salvaschermo non c'è `App.swift` (l'app vera): il nome e la versione si leggono dal bundle del salvaschermo.
enum SbuSeasonsApp {
    static let name = Bundle.seasons.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "Sbu Seasons"
    static let version = Bundle.seasons.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
}
