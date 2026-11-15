import Testing
@testable import CozySnow

struct AppNameTests {
    /// Il nome visibile viene da un posto solo (CFBundleDisplayName in project.yml): il rinomino tocca solo lì.
    @Test func theVisibleNameComesFromTheBundle() {
        #expect(CozySnowApp.name == "CozySnow")
    }

    @Test func theCartiglioCarriesTheAppNameNotTheSeason() {
        let cartiglio = SettingsView.cartiglio(on: .distantPast)
        #expect(cartiglio.hasPrefix("SBU · COZYSNOW · "))
        #expect(!cartiglio.contains("NEVE"))
    }
}
