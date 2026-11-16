import AppKit
import Testing
@testable import SbuSeasons

/// Sbu Seasons nasce da l'app di Simone Antoniciello: il suo nome e il link si vedono (MGS-614).
struct CreditsTests {
    @Test func theAboutPanelCreditsNameSimoneAndLinkToHisGitHub() {
        let credits = Credits.aboutPanel
        #expect(credits.string.contains("Simone Antoniciello"))
        #expect(credits.string.contains("idea"))
        let at = (credits.string as NSString).range(of: "github.com/antonsimo")
        #expect(at.location != NSNotFound)
        let link = credits.attribute(.link, at: at.location, effectiveRange: nil)
        #expect(link as? URL == URL(string: "https://github.com/antonsimo"))
    }

    /// Senza CFBundleIconName nel Finder, nel Dock e nel .dmg compare l'icona generica.
    @Test func theAppHasItsOwnIcon() {
        #expect(Bundle.main.object(forInfoDictionaryKey: "CFBundleIconName") as? String == "AppIcon")
    }
}
