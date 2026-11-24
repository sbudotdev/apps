import SbuKit
import SwiftUI

@main
struct SbuKeysApp: App {
    @State private var model = KeysModel()

    /// A menu bar app shows nothing at launch: the first time, the welcome asks for the permission.
    private static var welcomeAtLaunch: SceneLaunchBehavior {
        UserDefaults.standard.bool(forKey: WelcomeView.seenKey) ? .suppressed : .presented
    }

    var body: some Scene {
        MenuBarExtra {
            KeysPanel()
                .environment(model)
                .environment(\.sbuAccent, .keys)
        } label: {
            Image(systemName: "keyboard")
                .accessibilityLabel(Text("Sbu Keys"))
        }
        .menuBarExtraStyle(.window)

        Window("Benvenuto", id: WelcomeView.windowID) {
            WelcomeView()
                .environment(model)
                .environment(\.sbuAccent, .keys)
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        .defaultLaunchBehavior(Self.welcomeAtLaunch)
    }
}
