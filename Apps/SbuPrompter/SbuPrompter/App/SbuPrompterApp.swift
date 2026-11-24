import SbuKit
import SwiftUI

@main
struct SbuPrompterApp: App {
    @State private var model = AppModel()

    private static var libraryAtLaunch: SceneLaunchBehavior {
        #if DEBUG
        if DebugSnapshots.isRequested { return .presented }
        #endif
        return .suppressed
    }

    /// A menu bar app shows nothing at launch: the first time, the welcome says where it is.
    private static var welcomeAtLaunch: SceneLaunchBehavior {
        #if DEBUG
        if DebugSnapshots.isRequested { return .presented }
        #endif
        return UserDefaults.standard.bool(forKey: WelcomeView.seenKey) ? .suppressed : .presented
    }

    var body: some Scene {
        MenuBarExtra {
            MenuContent()
                .environment(model)
        } label: {
            Image(systemName: "text.aligncenter")
                .accessibilityLabel(Text("Sbu Prompter"))
        }

        Window("Libreria", id: LibraryView.windowID) {
            LibraryView()
                .environment(model)
                .environment(\.sbuAccent, .prompter)
                .modelContainer(model.container)
        }
        .defaultSize(width: 820, height: 560)
        .defaultLaunchBehavior(Self.libraryAtLaunch)

        Window("Benvenuto", id: WelcomeView.windowID) {
            WelcomeView()
                .environment(model)
                .environment(\.sbuAccent, .prompter)
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        .defaultLaunchBehavior(Self.welcomeAtLaunch)

        Settings {
            SettingsView()
                .environment(model)
                .environment(\.sbuAccent, .prompter)
        }
    }
}
