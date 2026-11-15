import Foundation
import SwiftUI
import Testing
@testable import SbuSeasons

/// La stagione si sceglie dal menu ❄︎ e dalle Impostazioni (MGS-472): un solo valore, `Settings.seasonID`.
/// I test usano i UserDefaults dell'app: rimettono la stagione di prima.
@MainActor
@Suite(.serialized)
struct SeasonChoiceTests {
    @Test func choosingInSettingsSavesTheSeason() {
        let settings = Settings.shared
        let before = settings.seasonID
        defer { settings.seasonID = before }

        Bindable(settings).seasonID.wrappedValue = Autumn.id   // la stessa Binding del Picker
        #expect(UserDefaults.standard.string(forKey: "season") == Autumn.id)
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
