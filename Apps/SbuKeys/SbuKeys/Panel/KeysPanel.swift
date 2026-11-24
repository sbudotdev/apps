import SbuKit
import SwiftUI

/// The menu bar panel: the keys pressed today, the sound on or off, the switch, volume and position.
struct KeysPanel: View {
    @Environment(KeysModel.self) private var model
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        @Bindable var model = model
        VStack(alignment: .leading, spacing: SbuTheme.space5) {
            if model.isListening {
                // The count changes at every key while the panel is open; the stop shows the sound is on.
                SbuFigure(
                    value: model.countToday().formatted(),
                    fullStop: model.isOn ? .set : .waiting,
                    context: Text("tasti oggi"))
            } else {
                SbuEmpty(sentence: "Consenti a Sbu Keys di sentire i tasti, in Monitoraggio input.") {
                    Button("Consenti", action: model.requestAccess)
                        .buttonStyle(.borderedProminent)
                        .tint(SbuTheme.ink)
                }
            }

            VStack(alignment: .leading, spacing: SbuTheme.space3) {
                Toggle("Suono dei tasti", isOn: $model.isOn)
                    .toggleStyle(SbuToggleStyle())
                Picker("Switch", selection: $model.keySwitch) {
                    ForEach(KeySwitch.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                LabeledContent("Volume") {
                    Slider(value: $model.volume, in: 0...1) { Text("Volume") }
                        .labelsHidden()
                }
                Toggle("Suono dalla posizione del tasto", isOn: $model.isSpatial)
                    .toggleStyle(SbuToggleStyle())
            }
            .disabled(!model.isOn)

            Divider()
            HStack {
                Button("Come si usa…") {
                    NSApp.activate()
                    openWindow(id: WelcomeView.windowID)
                }
                Spacer()
                Button("Esci") { NSApp.terminate(nil) }
                    .keyboardShortcut("q")
            }
            .buttonStyle(.borderless)
        }
        .padding(SbuTheme.space5)
        .frame(width: 340)
        .background(SbuTheme.paper)
        .tint(SbuTheme.ink)
    }
}

#Preview("Light") {
    KeysPanel()
        .environment(KeysModel(defaults: UserDefaults(suiteName: "preview")!))
        .environment(\.sbuAccent, .keys)
}

#Preview("Dark") {
    KeysPanel()
        .environment(KeysModel(defaults: UserDefaults(suiteName: "preview")!))
        .environment(\.sbuAccent, .keys)
        .preferredColorScheme(.dark)
}
