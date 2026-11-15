import Testing
@testable import SbuSeasons

struct AppNameTests {
    /// Il nome visibile viene da un posto solo (CFBundleDisplayName in project.yml): il rinomino tocca solo lì.
    @Test func theVisibleNameComesFromTheBundle() {
        #expect(SbuSeasonsApp.name == "Sbu Seasons")
    }

    /// Come `SBU · ABITUDINI · …` nelle app iPhone: "Sbu" una volta sola, poi il nome.
    @Test func theCartiglioCarriesTheAppNameNotTheSeason() {
        let cartiglio = SettingsView.cartiglio(on: .distantPast)
        #expect(cartiglio.hasPrefix("SBU · SEASONS · "))
        #expect(!cartiglio.contains("NEVE"))
    }
}
