import Foundation
import SwiftUI
import Testing
@testable import SbuSeasons

/// La stagione si sceglie dal menu ❄︎ e dalle Impostazioni (MGS-472): un solo valore, `Settings.seasonID`.
/// I test usano i UserDefaults di prova di Settings (non quelli veri): rimettono la stagione di prima.
@MainActor
@Suite(.serialized)
struct SeasonChoiceTests {
    /// SBU-160: sotto test Settings non legge le preferenze vere del Mac (che cambiano da un Mac all'altro).
    @Test func testsUseTheirOwnDefaults() {
        #expect(Settings.defaults !== UserDefaults.standard)
    }

    @Test func choosingInSettingsSavesTheSeason() {
        let settings = Settings.shared
        let before = settings.seasonID
        defer { settings.seasonID = before }

        Bindable(settings).seasonID.wrappedValue = Autumn.id   // la stessa Binding del Picker
        #expect(Settings.defaults.string(forKey: "season") == Autumn.id)
        #expect(settings.season.id == Autumn.id)
    }

    /// Il menu ❄︎ e la neve si aggiornano da qui: ogni cambio, da qualunque parte, arriva, anche il secondo.
    @Test(.timeLimit(.minutes(1)))
    func everyChangeReachesTheMenuAndTheSnow() async {
        let settings = Settings.shared
        let before = settings.seasonID
        defer { settings.seasonID = before }
        let (changes, continuation) = AsyncStream.makeStream(of: String.self)
        defer { continuation.finish() }
        settings.observeSeason { continuation.yield(Settings.shared.seasonID) }
        var next = changes.makeAsyncIterator()

        settings.seasonID = Spring.id
        #expect(await next.next() == Spring.id)
        settings.seasonID = Summer.id
        #expect(await next.next() == Summer.id)
    }
}
