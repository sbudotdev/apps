import SwiftUI

/// La scheda del pupazzo: la taglia delle tre palle e i vestiti. Ogni cambio si vede subito sul pupazzo.
struct SnowmanCard: View {
    @State private var look: SnowmanLook
    let apply: (SnowmanLook) -> Void

    init(look: SnowmanLook, apply: @escaping (SnowmanLook) -> Void) {
        _look = State(initialValue: look)
        self.apply = apply
    }

    var body: some View {
        Form {
            Section("Palle") {
                sizePicker("Pancia", ball: 0)
                sizePicker("Petto", ball: 1)
                sizePicker("Testa", ball: 2)
            }
            Section("Vestiti") {
                Picker("Cappello", selection: $look.hat) {
                    Text("Nessuno").tag(SnowmanLook.Hat.none)
                    Text("Cilindro").tag(SnowmanLook.Hat.topHat)
                    Text("Berretto").tag(SnowmanLook.Hat.beanie)
                }
                Picker("Sciarpa", selection: $look.scarf) {
                    Text("Nessuna").tag(SnowmanLook.Scarf.none)
                    Text("Rossa").tag(SnowmanLook.Scarf.red)
                    Text("Verde").tag(SnowmanLook.Scarf.green)
                }
                Picker("Naso", selection: $look.nose) {
                    Text("Carota").tag(SnowmanLook.Nose.carrot)
                    Text("Carbone").tag(SnowmanLook.Nose.coal)
                    Text("Nessuno").tag(SnowmanLook.Nose.none)
                }
                Toggle("Bottoni", isOn: $look.buttons)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .scrollDisabled(true)
        .background(Quaderno.paper.color)
        .tint(Quaderno.ink.color)
        .toggleStyle(.switch)
        .frame(width: Quaderno.gridCell * 14)
        .fixedSize(horizontal: false, vertical: true)
        .onChange(of: look) { apply(look) }
    }

    private func sizePicker(_ title: LocalizedStringKey, ball: Int) -> some View {
        Picker(title, selection: $look.balls[ball]) {
            Text("Piccola").tag(SnowmanLook.Size.small)
            Text("Media").tag(SnowmanLook.Size.medium)
            Text("Grande").tag(SnowmanLook.Size.large)
        }
        .pickerStyle(.segmented)
    }
}

#Preview("Chiaro") {
    SnowmanCard(look: SnowmanLook()) { _ in }
        .preferredColorScheme(.light)
}

#Preview("Scuro") {
    SnowmanCard(look: SnowmanLook()) { _ in }
        .preferredColorScheme(.dark)
}
