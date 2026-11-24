import SwiftUI

/// The menu bar menu: play, show, cues, voice, library and settings.
struct MenuContent: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        let controller = model.controller
        Button(controller.isPlaying ? "Pausa" : "Avvia") { model.perform(.togglePlay) }
            .disabled(controller.script.words.isEmpty)
        Button(model.isPrompterVisible ? "Nascondi prompter" : "Mostra prompter") { model.perform(.toggleVisibility) }
        Button("Riavvolgi") { model.perform(.rewind) }
        Toggle("Lascia passare i clic", isOn: Bindable(model.settings).clickThrough)

        if !controller.script.cues.isEmpty {
            Menu("Sezioni") {
                ForEach(controller.script.cues.indices, id: \.self) { index in
                    // A checkmark on the section being read; choosing one jumps there.
                    Toggle(CueTitle.text(controller.script.cues[index].title, index: index), isOn: Binding(
                        get: { controller.currentCue == index },
                        set: { _ in model.perform(.jumpToCue(index)) }))
                }
                Divider()
                Button("Torna dove eri") { model.perform(.returnFromCue) }
                    .disabled(!controller.canReturnFromCue)
            }
        }

        Divider()
        Picker("Scorrimento", selection: Bindable(model.settings).mode) {
            Text("A velocità fissa").tag(PrompterController.Mode.fixed)
            Text("A voce").tag(PrompterController.Mode.voice)
        }
        Button("Più veloce") { model.perform(.faster) }
        Button("Più lento") { model.perform(.slower) }

        Divider()
        if let name = model.remote.connectedName {
            Text("Telecomando: \(name)")
        } else {
            // The iPhone asks for this code the first time; it changes after each pairing.
            Text("Codice per l'iPhone: \(model.remote.code)")
        }
        // Always there: it also gives a new code when someone nearby has been guessing it.
        Button("Dimentica gli iPhone abbinati") { model.remote.forgetAll() }

        Divider()
        Button("Libreria…") {
            NSApp.activate()
            openWindow(id: LibraryView.windowID)
        }
        Button("Come si usa…") {
            NSApp.activate()
            openWindow(id: WelcomeView.windowID)
        }
        Button("Impostazioni…") {
            NSApp.activate()
            openSettings()
        }
        .keyboardShortcut(",")
        Divider()
        Button("Esci da Sbu Prompter") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }
}
