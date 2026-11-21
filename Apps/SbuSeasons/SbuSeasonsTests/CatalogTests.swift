import Foundation
import Testing

/// Le otto lingue dell'app (SBU-199): ogni voce dei cataloghi c'è in tutte, tradotta, con gli stessi segnaposto
/// dell'italiano. Legge i file sorgente, così una voce nuova senza traduzioni fa fallire il test.
struct CatalogTests {
    static let languages = ["it", "en", "de", "fr", "es", "ja", "pt", "nl"]

    private static func catalog(_ name: String) throws -> [String: [String: Any]] {
        let url = URL(filePath: #filePath).deletingLastPathComponent().appending(path: "../SbuSeasons/\(name).xcstrings")
        let json = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any]
        return try #require(json?["strings"] as? [String: [String: Any]])
    }

    /// Le forme di una lingua: una sola, o una per plurale (`one`, `other`…).
    private static func forms(_ localization: [String: Any]) -> [String: [String: Any]] {
        if let unit = localization["stringUnit"] as? [String: Any] { return ["": unit] }
        let plural = (localization["variations"] as? [String: Any])?["plural"] as? [String: [String: Any]] ?? [:]
        return plural.compactMapValues { $0["stringUnit"] as? [String: Any] }
    }

    /// `%@`, `%lld`, `%1$@`… senza il numero di posizione, in ordine: l'ordine nella frase può cambiare tra le lingue.
    static func placeholders(_ text: String) -> [String] {
        text.matches(of: /%(?:\d+\$)?(lld|ld|d|@|\.?\d*f)/).map { String($0.output.1) }.sorted()
    }

    @Test(arguments: ["Localizable", "InfoPlist"])
    func everyEntryIsInAllLanguagesWithTheSamePlaceholders(_ name: String) throws {
        for (key, entry) in try Self.catalog(name) where entry["shouldTranslate"] as? Bool != false {
            let localizations = entry["localizations"] as? [String: [String: Any]] ?? [:]
            let source = Self.placeholders(key)
            for language in Self.languages {
                // L'italiano può mancare: la chiave è già il testo italiano.
                guard let localization = localizations[language] else {
                    #expect(language == "it", "\(name): «\(key)» manca in \(language)")
                    continue
                }
                let forms = Self.forms(localization)
                #expect(!forms.isEmpty, "\(name): «\(key)» in \(language) è vuota")
                for (form, unit) in forms {
                    let value = unit["value"] as? String ?? ""
                    #expect(unit["state"] as? String == "translated" && !value.isEmpty, "\(name): «\(key)» in \(language) \(form) non è tradotta")
                    // In InfoPlist le chiavi sono nomi (`CFBundleName`), non testo: lì i segnaposto non si confrontano.
                    if name == "Localizable" {
                        #expect(Self.placeholders(value) == source, "\(name): «\(key)» in \(language) \(form): \(value)")
                    }
                }
            }
        }
    }

    @Test func placeholdersIgnorePositionAndOrder() {
        #expect(Self.placeholders("%2$@ e %1$lld") == ["@", "lld"])
        #expect(Self.placeholders("%lld di %lld") == ["lld", "lld"])
        #expect(Self.placeholders("%.0f pt") == [".0f"])
        #expect(Self.placeholders("niente") == [])
    }
}
