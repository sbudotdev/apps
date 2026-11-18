import Foundation
import Testing
@testable import SbuSeasons

/// Le stringhe stanno in `Localizable.xcstrings` (ADR-0022): italiano di sviluppo, più l'inglese.
struct LocalizationTests {
    private static let english = Bundle.main.path(forResource: "en", ofType: "lproj").flatMap(Bundle.init(path:))

    @Test(arguments: [
        ("Mostra l'effetto", "Show the Effect"),
        ("Effetto", "Effect"),
        ("Dietro le finestre", "Behind Windows"),
        ("Togli quello che si è posato", "Clear What Has Settled"),
        ("Giochi", "Toys"),
        ("Natale", "Christmas"),
        ("Tour di benvenuto…", "Welcome Tour…"),
        ("Da provare adesso", "Try These Now"),
        ("%lld di %lld", "%lld of %lld"),
        ("Esci da %@", "Quit %@"),
        ("Impostazioni…", "Settings…"),
        ("Leggera", "Light"),
        ("Quantità", "Amount"),
        ("Neve", "Snow"),
        ("Primavera", "Spring"),
        ("Estate", "Summer"),
        ("Autunno", "Autumn"),
        ("Lucciole", "Fireflies"),
        ("Stelle cadenti", "Shooting Stars"),
        ("Sereno", "Clear Skies"),
        ("Pioggia sul vetro", "Rain on the Glass"),
        ("Temporale", "Thunderstorm"),
        ("Nebbia", "Mist"),
        ("Nuvole", "Clouds"),
        ("Suoni", "Sounds"),
        ("Volume", "Volume"),
        ("Riproduci i suoni", "Play Sounds"),
        ("Togli le palle di neve", "Clear the Snowballs"),
        ("Scuoti la palla di vetro", "Shake the Snow Globe"),
        ("Manda lo spazzaneve", "Send the Snowplough"),
        ("Togli la funivia", "Remove the Cable Car"),
        ("Metti in pausa i giochi", "Pause the Toys"),
        ("Informazioni su %@", "About %@"),
        ("Nata da un'idea di Simone Antoniciello", "Based on an idea by Simone Antoniciello"),
    ])
    func theEnglishTranslationIsInTheBundle(_ italian: String, _ english: String) throws {
        let bundle = try #require(Self.english, "manca en.lproj nel bundle")
        #expect(bundle.localizedString(forKey: italian, value: nil, table: nil) == english)
    }
}
