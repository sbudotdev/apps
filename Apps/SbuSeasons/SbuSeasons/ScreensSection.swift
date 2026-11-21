import SwiftUI

/// Impostazioni → Schermi (SBU-185, SBU-227): un interruttore per schermo, la scelta per UUID (`NSScreen.wallpaperKey`).
/// L'ultimo schermo acceso non si spegne. Si mostra solo con più di uno schermo.
struct ScreensSection: View {
    /// Gli schermi collegati: nome da mostrare e chiave con cui si salva la scelta.
    var screens: [(name: String, key: String)] = NSScreen.screens.map { ($0.localizedName, $0.wallpaperKey) }
    @Bindable private var settings = Settings.shared

    var body: some View {
        let connected = screens.map(\.key)
        Section {
            ForEach(screens, id: \.key) { screen in
                let on = settings.values.showsEffect(onScreen: screen.key, connected: connected)
                Toggle(screen.name, isOn: Binding {
                    on
                } set: { on in
                    settings.values.setEffect(on, onScreen: screen.key)
                })
                .disabled(on && !settings.values.canTurnOffEffect(onScreen: screen.key, connected: connected))
            }
        } header: {
            Text("Schermi")
        } footer: {
            Text("L'ultimo schermo acceso non si spegne: per togliere l'effetto da tutti usa Mostra l'effetto (⌘S) nel menu ❄︎.")
                .foregroundStyle(Quaderno.inkMuted.color)
        }
    }
}

#Preview("Chiaro") {
    Form { ScreensSection(screens: [("Display Retina integrato", "A"), ("Studio Display", "B")]) }
        .formStyle(.grouped)
        .preferredColorScheme(.light)
}

#Preview("Scuro") {
    Form { ScreensSection(screens: [("Display Retina integrato", "A"), ("Studio Display", "B")]) }
        .formStyle(.grouped)
        .preferredColorScheme(.dark)
}
