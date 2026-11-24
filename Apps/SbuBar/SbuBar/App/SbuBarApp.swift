import SbuKit
import SwiftUI

@main
struct SbuBarApp: App {
    var body: some Scene {
        MenuBarExtra {
            Text("Sbu Bar")
                .padding(SbuTheme.space4)
                .environment(\.sbuAccent, .bar)
        } label: {
            Image(systemName: "menubar.rectangle")
                .accessibilityLabel(Text("Sbu Bar"))
        }
        .menuBarExtraStyle(.window)
    }
}
