import Testing
@testable import SbuSeasons

struct AppNameTests {
    /// Il nome visibile viene da un posto solo (CFBundleDisplayName in project.yml): il rinomino tocca solo lì.
    @Test func theVisibleNameComesFromTheBundle() {
        #expect(SbuSeasonsApp.name == "SbuSeasons")
    }

    @Test func theCartiglioCarriesTheAppNameNotTheSeason() {
        let cartiglio = SettingsView.cartiglio(on: .distantPast)
        #expect(cartiglio.hasPrefix("SBU · SBUSEASONS · "))
        #expect(!cartiglio.contains("NEVE"))
    }
}
