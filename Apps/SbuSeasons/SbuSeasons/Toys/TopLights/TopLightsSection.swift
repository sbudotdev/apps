import SwiftUI

/// Impostazioni → Luci in alto (SBU-229): accese o spente, colori, forma delle lampadine e animazione.
struct TopLightsSection: View {
    @Bindable private var settings = Settings.shared

    var body: some View {
        Section {
            Toggle("Mostra le luci", isOn: $settings.values.topLights)
            Picker("Colori", selection: $settings.values.topLightsPalette) {
                Text("Multicolore").tag(TopLights.Palette.multicolor)
                Text("Caldi").tag(TopLights.Palette.warm)
                Text("Freddi").tag(TopLights.Palette.cold)
                Text("Un colore solo").tag(TopLights.Palette.single)
            }
            if settings.values.topLightsPalette == .single {
                Picker("Colore", selection: $settings.values.topLightsColor) {
                    Text("Rosso").tag(TopLights.SingleColor.red)
                    Text("Oro").tag(TopLights.SingleColor.gold)
                    Text("Bianco").tag(TopLights.SingleColor.white)
                    Text("Blu").tag(TopLights.SingleColor.blue)
                    Text("Verde").tag(TopLights.SingleColor.green)
                }
            }
            Picker("Lampadine", selection: $settings.values.topLightsShape) {
                Text("Tonde").tag(TopLights.Shape.round)
                Text("A goccia").tag(TopLights.Shape.drop)
                Text("A stella").tag(TopLights.Shape.star)
            }
            Picker("Animazione", selection: $settings.values.topLightsAnimation) {
                Text("Fisse").tag(TopLights.Animation.steady)
                Text("A turno").tag(TopLights.Animation.chase)
                Text("Lampeggio lento").tag(TopLights.Animation.slowBlink)
                Text("Onda").tag(TopLights.Animation.wave)
            }
        } header: {
            Text("Luci in alto")
        } footer: {
            Text("Un filo di luci appena sotto la barra dei menu, sugli schermi scelti, con ogni effetto e anche a effetto spento. I clic passano attraverso. Con Riduci movimento restano fisse.")
                .foregroundStyle(Quaderno.inkMuted.color)
        }
    }
}

#Preview("Chiaro") {
    Form { TopLightsSection() }
        .formStyle(.grouped)
        .preferredColorScheme(.light)
}

#Preview("Scuro") {
    Form { TopLightsSection() }
        .formStyle(.grouped)
        .preferredColorScheme(.dark)
}
