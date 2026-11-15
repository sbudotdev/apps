import Foundation
import Testing
@testable import SbuSeasons

/// Chi usava l'app con il nome di prima ritrova neve accesa o spenta e impostazioni.
struct PreviousDefaultsTests {
    /// Domini di UserDefaults usa e getta, cancellati alla fine con il loro file:
    /// `removePersistentDomain` da solo lascia un .plist vuoto in ~/Library/Preferences.
    private func withSuites(_ count: Int, _ body: ([String], [UserDefaults]) throws -> Void) rethrows {
        let names = (0..<count).map { _ in "test.sbuseasons.\(UUID().uuidString)" }
        defer {
            let preferences = URL.libraryDirectory.appending(path: "Preferences")
            for name in names {
                UserDefaults.standard.removePersistentDomain(forName: name)
                try? FileManager.default.removeItem(at: preferences.appending(path: "\(name).plist"))
            }
        }
        try body(names, names.map { UserDefaults(suiteName: $0)! })
    }

    @Test func savedValuesMoveToTheNewName() {
        withSuites(2) { names, suites in
            let (new, old) = (suites[0], suites[1])
            old.set(Data("{\"wind\":40}".utf8), forKey: "settings")
            old.set(false, forKey: "isSnowing")
            PreviousDefaults.migrate(into: new, from: [names[1]])
            #expect(SnowSettings(saved: new.data(forKey: "settings")).wind == 40)
            #expect(new.object(forKey: "isSnowing") as? Bool == false)
        }
    }

    @Test func valuesAlreadySavedUnderTheNewNameWin() {
        withSuites(2) { names, suites in
            let (new, old) = (suites[0], suites[1])
            new.set(true, forKey: "isSnowing")
            old.set(false, forKey: "isSnowing")
            PreviousDefaults.migrate(into: new, from: [names[1]])
            #expect(new.object(forKey: "isSnowing") as? Bool == true)
        }
    }

    @Test func theMostRecentOldNameWins() {
        withSuites(3) { names, suites in
            suites[1].set(false, forKey: "isSnowing")   // il nome più recente
            suites[2].set(true, forKey: "isSnowing")
            PreviousDefaults.migrate(into: suites[0], from: [names[1], names[2]])
            #expect(suites[0].object(forKey: "isSnowing") as? Bool == false)
        }
    }
}
