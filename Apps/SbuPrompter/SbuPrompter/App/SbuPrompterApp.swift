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

        Settings {
            SettingsView()
                .environment(model)
                .environment(\.sbuAccent, .prompter)
        }
    }
}
