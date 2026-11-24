import SbuKit
import SwiftUI

/// The first launch: what the prompter is, how to bring your own scripts, how to start.
/// One screen, no carousel and no permission prompt: the microphone is asked for only
/// when you choose voice scrolling.
struct WelcomeView: View {
    static let windowID = "welcome"
    /// Set once the window has been seen, so it opens by itself only the first time.
    static let seenKey = "welcomeSeen"

    @Environment(AppModel.self) private var model
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        VStack(alignment: .leading, spacing: SbuTheme.space5) {
            SbuScreenTitle("Sbu Prompter", cartiglio: String(localized: "Sbu · Prompter · Benvenuto"))

            VStack(alignment: .leading, spacing: SbuTheme.space4) {
                WelcomeStep(symbol: "macbook", title: "Sotto la fotocamera",
                            text: "Il copione scorre nel notch, vicino all'obiettivo: guardi chi ti ascolta mentre leggi. Lo vedi solo tu, anche quando condividi lo schermo.")
                WelcomeStep(symbol: "square.and.arrow.down", title: "I tuoi copioni",
                            text: "Trascina i file nella libreria, scegli Importa, oppure copia il testo e scegli Incolla come copione. Vanno bene file di testo, Markdown, RTF, Word, OpenDocument, HTML e PDF.")
                WelcomeStep(symbol: "number", title: "Le sezioni",
                            text: "Una riga che inizia con # apre una sezione: ci salti dal menu o dal telecomando.")
                WelcomeStep(symbol: "command", title: "Avvia e ferma",
                            text: "Premi \(model.settings.combo(for: .togglePlay).label) in qualsiasi app. Il resto è nel menu \(Image(systemName: "text.aligncenter")) in alto a destra.")
            }

            HStack {
                Spacer()
                Button("Più tardi") { close() }
                    .keyboardShortcut(.cancelAction)
                Button("Apri la libreria") {
                    close()
                    NSApp.activate()
                    openWindow(id: LibraryView.windowID)
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .tint(SbuTheme.ink)
            }
        }
        .padding(SbuTheme.space6)
        .frame(width: 520)
        .background(SbuTheme.paper)
        .onAppear { UserDefaults.standard.set(true, forKey: Self.seenKey) }
    }

    private func close() {
        dismissWindow(id: Self.windowID)
    }
}
