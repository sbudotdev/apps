import AppKit
import Foundation
import Testing
@testable import SbuSeasons

/// Il tour di benvenuto: le pagine, le due cose da provare e quando si apre da solo.
struct TourTests {
    private func freshDefaults() -> UserDefaults {
        let name = "tour-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test func thePagesFollowTheTicketOrder() {
        #expect(TourPage.allCases == [.welcome, .effects, .toys, .christmas, .night, .wallpapers])
    }

    @Test(arguments: TourPage.allCases)
    func everyPageHasTitleTextAndARealSymbol(_ page: TourPage) {
        #expect(!page.title.isEmpty)
        #expect(!page.text.isEmpty)
        #expect(NSImage(systemSymbolName: page.symbol, accessibilityDescription: nil) != nil)
    }

    @Test func itOpensByItselfOnlyTheFirstTime() {
        let progress = TourProgress(defaults: freshDefaults())
        #expect(progress.opensAtLaunch)
        progress.markSeen()
        #expect(!progress.opensAtLaunch)
    }

    @Test func theTwoChallengesAreCrossedOffWhenDoneAndRemembered() {
        let defaults = freshDefaults()
        let progress = TourProgress(defaults: defaults)
        #expect(TourChallenge.allCases.count == 2)
        #expect(progress.done.isEmpty)

        progress.complete(.shakeGlobe)
        progress.complete(.shakeGlobe)   // la seconda volta non cambia niente
        #expect(progress.done == [.shakeGlobe])
        #expect(!progress.allDone)

        progress.complete(.changeEffect)
        #expect(progress.allDone)
        #expect(TourProgress(defaults: defaults).done == Set(TourChallenge.allCases))
    }

    @Test(arguments: TourChallenge.allCases)
    func everyChallengeSaysWhatToDo(_ challenge: TourChallenge) {
        #expect(!challenge.title.isEmpty)
    }
}
