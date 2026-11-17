import Foundation
import Testing
@testable import SbuSeasons

/// Le stringhe stanno in `Localizable.xcstrings` (ADR-0022): italiano di sviluppo, più l'inglese.
struct LocalizationTests {
    private static let english = Bundle.main.path(forResource: "en", ofType: "lproj").flatMap(Bundle.init(path:))

    @Test(arguments: [
        ("Fai nevicare", "Let It Snow"),
        ("Esci da %@", "Quit %@"),
        ("Impostazioni…", "Settings…"),
        ("Leggera", "Light"),
        ("Quantità di fiocchi", "Number of Flakes"),
        ("Stagione", "Season"),
        ("Neve", "Snow"),
        ("Primavera", "Spring"),
        ("Estate", "Summer"),
        ("Autunno", "Autumn"),
        ("Suoni", "Sounds"),
        ("Volume", "Volume"),
        ("Riproduci i suoni", "Play Sounds"),
        ("Informazioni su %@", "About %@"),
        ("Nata da un'idea di Simone Antoniciello", "Based on an idea by Simone Antoniciello"),
    ])
    func theEnglishTranslationIsInTheBundle(_ italian: String, _ english: String) throws {
        let bundle = try #require(Self.english, "manca en.lproj nel bundle")
        #expect(bundle.localizedString(forKey: italian, value: nil, table: nil) == english)
    }
}
