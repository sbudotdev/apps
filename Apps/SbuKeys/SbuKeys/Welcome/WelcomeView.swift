import SbuKit
import SwiftUI

/// The first launch: what the app does, the one permission it needs and why, where it lives.
struct WelcomeView: View {
    static let windowID = "welcome"
    /// Set once the window has been seen, so it opens by itself only the first time.
    static let seenKey = "welcomeSeen"

    @Environment(KeysModel.self) private var model
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        VStack(alignment: .leading, spacing: SbuTheme.space5) {
            SbuScreenTitle("Sbu Keys", cartiglio: String(localized: "Sbu · Keys · Benvenuto"))

            VStack(alignment: .leading, spacing: SbuTheme.space4) {
                WelcomeStep(symbol: "keyboard", title: "Un suono a ogni tasto",
                            text: "In ogni app, come una tastiera meccanica. Scegli lo switch e il volume dal menu \(Image(systemName: "keyboard")) in alto a destra.")
                WelcomeStep(symbol: "hand.raised", title: "Un solo permesso",
                            text: "Per sentire i tasti serve Monitoraggio input. Sbu Keys conta i tasti e non legge mai cosa scrivi; nelle password non suona.")
                WelcomeStep(symbol: "lock", title: "Tutto sul Mac",
                            text: "Nessuna rete, nessun account. Il conteggio di oggi resta qui.")
            }

            HStack {
                Spacer()
                if model.isListening {
                    Button("Fatto", action: close)
                        .keyboardShortcut(.defaultAction)
                } else {
                    Button("Più tardi", action: close)
                        .keyboardShortcut(.cancelAction)
                    Button("Consenti", action: model.requestAccess)
                        .keyboardShortcut(.defaultAction)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(SbuTheme.ink)
        }
        .padding(SbuTheme.space6)
        .frame(width: 520)
        .background(SbuTheme.paper)
        .onAppear {
            UserDefaults.standard.set(true, forKey: Self.seenKey)
            // A menu bar app is never active at launch: without this the window opens behind the others.
            NSApp.activate()
        }
    }

    private func close() {
        dismissWindow(id: Self.windowID)
    }
}

#Preview("Light") {
    WelcomeView()
        .environment(KeysModel(defaults: UserDefaults(suiteName: "preview")!))
}

#Preview("Dark") {
    WelcomeView()
        .environment(KeysModel(defaults: UserDefaults(suiteName: "preview")!))
        .preferredColorScheme(.dark)
}
