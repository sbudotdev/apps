import SwiftUI

@main
struct SbuPrompterApp: App {
    var body: some Scene {
        MenuBarExtra("Sbu Prompter", systemImage: "text.alignleft") {
            Button("Esci") { NSApp.terminate(nil) }
        }
    }
}
