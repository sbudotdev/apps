import SwiftUI

/// La scheda del pupazzo: la taglia delle tre palle e i vestiti. Ogni cambio si vede subito sul pupazzo.
struct SnowmanCard: View {
    @State private var look: SnowmanLook
    let apply: (SnowmanLook) -> Void
    /// «Manda…»: il pupazzo diventa un file da mandare (SBU-200).
    let send: () -> Void

    init(look: SnowmanLook, send: @escaping () -> Void = {}, apply: @escaping (SnowmanLook) -> Void) {
        _look = State(initialValue: look)
        self.send = send
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
                    Text("Da cowboy").tag(SnowmanLook.Hat.cowboy)
                    Text("Da festa").tag(SnowmanLook.Hat.party)
                    Text("Da elfo").tag(SnowmanLook.Hat.elf)
                    Text("Da pirata").tag(SnowmanLook.Hat.pirate)
                    Text("Corona").tag(SnowmanLook.Hat.crown)
                    Text("Corna di renna").tag(SnowmanLook.Hat.antlers)
                }
                Picker("Sciarpa", selection: $look.scarf) {
                    Text("Nessuna").tag(SnowmanLook.Scarf.none)
                    Text("Rossa").tag(SnowmanLook.Scarf.red)
                    Text("Verde").tag(SnowmanLook.Scarf.green)
                    Text("A righe").tag(SnowmanLook.Scarf.striped)
                }
                Picker("Occhi", selection: $look.eyes) {
                    Text("Carbone").tag(SnowmanLook.Eyes.coal)
                    Text("Stelle").tag(SnowmanLook.Eyes.stars)
                }
                Picker("Naso", selection: $look.nose) {
                    Text("Carota").tag(SnowmanLook.Nose.carrot)
                    Text("Carbone").tag(SnowmanLook.Nose.coal)
                    Text("Nessuno").tag(SnowmanLook.Nose.none)
                }
                Toggle("Bottoni", isOn: $look.buttons)
                Toggle("Muffole", isOn: $look.mittens)
                Toggle("Papillon", isOn: $look.bowTie)
                Toggle("Maglione", isOn: $look.sweater)
                Toggle("Mantello", isOn: $look.cape)
            }
            Section {
                Button("Manda…", action: send)
            } footer: {
                Text("Diventa un file da mandare con AirDrop, Messaggi o Mail. Chi lo apre con Sbu Seasons se lo trova sullo schermo.")
                    .foregroundStyle(Quaderno.inkMuted.color)
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
