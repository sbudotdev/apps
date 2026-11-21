import Testing
@testable import SbuSeasons

/// «Novità»: la schedina nel menu dopo un aggiornamento, una volta sola.
struct WhatsNewTests {
    @Test func afterAnUpdateTheCardShowsOnce() {
        #expect(WhatsNew.pending(version: "2.1.0", seen: "2.0", firstRun: false) == "2.1")
        #expect(WhatsNew.pending(version: "2.1.0", seen: "2.1", firstRun: false) == nil)
    }

    /// Chi aveva la 2.0.3 non ha mai salvato niente: anche per lui è un aggiornamento.
    @Test func comingFromAVersionWithoutTheCardCounts() {
        #expect(WhatsNew.pending(version: "2.1.0", seen: nil, firstRun: false) == "2.1")
    }

    /// Alla prima apertura c'è già il tour: niente novità.
    @Test func aNewInstallSeesNoCard() {
        #expect(WhatsNew.pending(version: "2.1.0", seen: nil, firstRun: true) == nil)
    }

    /// Le correzioni (2.1.1) non hanno una schedina loro: se la 2.1 è già vista, niente.
    @Test func bugFixesDoNotShowItAgain() {
        #expect(WhatsNew.pending(version: "2.1.1", seen: "2.1", firstRun: false) == nil)
    }

    @Test func aVersionWithoutNotesShowsNothing() {
        #expect(WhatsNew.pending(version: "1.9", seen: nil, firstRun: false) == nil)
    }

    @Test func theCurrentVersionHasNotes() {
        let release = WhatsNew.release(of: SbuSeasonsApp.version)
        #expect(!(WhatsNew.notes[release] ?? []).isEmpty, "mancano le novità della \(release)")
    }
}
