import SbuKit
import Speech
import SwiftUI

/// The Settings window: look, position, scrolling and shortcuts.
struct SettingsView: View {
    @AppStorage("settingsTab") private var tab = "appearance"

    var body: some View {
        TabView(selection: $tab) {
            Tab("Aspetto", systemImage: "textformat.size", value: "appearance") { AppearanceSettings() }
            Tab("Posizione", systemImage: "macbook", value: "position") { PositionSettings() }
            Tab("Scorrimento", systemImage: "arrow.down.to.line", value: "scrolling") { ScrollingSettings() }
            Tab("Scorciatoie", systemImage: "command", value: "shortcuts") { ShortcutSettings() }
        }
        .frame(width: 480)
        .scenePadding()
    }
}

private struct AppearanceSettings: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var settings = model.settings
        Form {
            Picker("Colore del testo", selection: $settings.textColor) {
                Text("Chiaro").tag(PrompterSettings.TextColor.ink)
                Text("Grigio").tag(PrompterSettings.TextColor.muted)
                Text("Ciano").tag(PrompterSettings.TextColor.accent)
            }
            LabeledContent("Dimensione del testo") {
                Slider(value: $settings.fontSize, in: PrompterSettings.fontSizes, step: 2) {
                    Text("Dimensione del testo")
                } minimumValueLabel: {
                    Image(systemName: "textformat.size.smaller").accessibilityHidden(true)
                } maximumValueLabel: {
                    Image(systemName: "textformat.size.larger").accessibilityHidden(true)
                }
                .labelsHidden()
            }
            LabeledContent("Opacità dello sfondo") {
                Slider(value: $settings.backgroundOpacity, in: PrompterSettings.opacities) {
                    Text("Opacità dello sfondo")
                }
                .labelsHidden()
            }
            Toggle("Specchia il testo", isOn: $settings.isMirrored)
            Text("Per leggere attraverso il vetro di un teleprompter.")
                .font(SbuTheme.caption)
                .foregroundStyle(SbuTheme.inkMuted)
        }
    }
}

private struct PositionSettings: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var settings = model.settings
        Form {
            Picker("Prompter", selection: $settings.layout) {
                Text("Sotto la fotocamera").tag(PrompterSettings.Layout.notch)
                Text("Finestra mobile").tag(PrompterSettings.Layout.floating)
            }
            .pickerStyle(.radioGroup)
            if settings.layout == .notch {
                LabeledContent("Larghezza") {
                    Slider(value: $settings.width, in: PrompterSettings.widths, step: 10) { Text("Larghezza") }
                        .labelsHidden()
                }
                LabeledContent("Altezza") {
                    Slider(value: $settings.height, in: PrompterSettings.heights, step: 10) { Text("Altezza") }
                        .labelsHidden()
                }
                Text("Sui Mac senza notch il prompter è una pillola in alto al centro.")
                    .font(SbuTheme.caption)
                    .foregroundStyle(SbuTheme.inkMuted)
            } else {
                Text("Trascina il prompter dove vuoi e ridimensionalo dai bordi: la posizione resta.")
                    .font(SbuTheme.caption)
                    .foregroundStyle(SbuTheme.inkMuted)
            }
        }
        .onChange(of: settings.layout) { model.relayout() }
        .onChange(of: settings.width) { model.relayout() }
        .onChange(of: settings.height) { model.relayout() }
    }
}

private struct ScrollingSettings: View {
    @Environment(AppModel.self) private var model
    @State private var microphones: [Microphones.Device] = []

    var body: some View {
        @Bindable var settings = model.settings
        Form {
            Picker("Scorrimento", selection: $settings.mode) {
                Text("A velocità fissa").tag(PrompterController.Mode.fixed)
                Text("A voce").tag(PrompterController.Mode.voice)
            }
            .pickerStyle(.radioGroup)
            if settings.mode == .fixed {
                LabeledContent("Velocità") {
                    Slider(value: $settings.speed, in: ScrollEngine.speedRange, step: ScrollEngine.speedStep) { Text("Velocità") }
                        .labelsHidden()
                }
            } else {
                Picker("Lingua", selection: $settings.voiceLocale) {
                    ForEach(Self.locales, id: \.self) { identifier in
                        Text(Locale.current.localizedString(forIdentifier: identifier) ?? identifier).tag(identifier)
                    }
                }
                Picker("Microfono", selection: $settings.microphone) {
                    Text("Quello del sistema").tag(String?.none)
                    ForEach(microphones) { Text(verbatim: $0.name).tag(Optional($0.id)) }
                    if let chosen = settings.microphone, !microphones.contains(where: { $0.id == chosen }) {
                        Text("Non collegato").tag(Optional(chosen))
                    }
                }
                Text("Il testo segue le parole che leggi e si ferma quando taci. La voce resta sul Mac.")
                    .font(SbuTheme.caption)
                    .foregroundStyle(SbuTheme.inkMuted)
                if let problem = model.speech.problem {
                    Label { Text(problem.message) } icon: { Image(systemName: "exclamationmark.triangle") }
                        .font(SbuTheme.caption)
                        .foregroundStyle(SbuTheme.warning)
                }
            }
            Picker("Conto alla rovescia", selection: $settings.countdown) {
                ForEach(Countdown.choices, id: \.self) { seconds in
                    if seconds == 0 { Text("Nessuno").tag(seconds) } else { Text("\(seconds) s").tag(seconds) }
                }
            }
        }
        .onAppear { microphones = Microphones.all }
    }

    private static let locales: [String] = {
        let all = SFSpeechRecognizer.supportedLocales().map { $0.identifier(.bcp47) }
        return all.sorted { (Locale.current.localizedString(forIdentifier: $0) ?? $0) < (Locale.current.localizedString(forIdentifier: $1) ?? $1) }
    }()
}

private struct ShortcutSettings: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Form {
            ForEach(ShortcutAction.allCases, id: \.self) { action in
                LabeledContent(action.title) {
                    ShortcutRecorder(action: action)
                }
            }
            Text("Funzionano in ogni app. Clicca una scorciatoia e premi i tasti nuovi.")
                .font(SbuTheme.caption)
                .foregroundStyle(SbuTheme.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
            Button("Ripristina") {
                model.settings.shortcuts = Dictionary(uniqueKeysWithValues: ShortcutAction.allCases.map { ($0, $0.defaultCombo) })
                model.suspendShortcuts(false)
            }
        }
    }
}
