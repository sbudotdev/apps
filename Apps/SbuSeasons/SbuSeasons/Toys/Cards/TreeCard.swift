import SwiftUI

/// La scheda dell'albero: che cosa appende il prossimo clic sui rami, quanto è alto, e il taglio.
/// Aperta su una decorazione (`focus`), anche la sua grandezza, la rotazione e "Togli".
struct TreeCard: View {
    @State private var look: TreeLook
    @State private var focus: Int?
    let apply: (TreeLook) -> Void
    let cut: () -> Void

    init(look: TreeLook, focus: Int?, apply: @escaping (TreeLook) -> Void, cut: @escaping () -> Void) {
        _look = State(initialValue: look)
        _focus = State(initialValue: focus)
        self.apply = apply
        self.cut = cut
    }

    var body: some View {
        Form {
            Section {
                Picker("Appendi", selection: $look.hanging) {
                    ForEach(DecorationKind.allCases, id: \.self) { kind in
                        Text(kind.title).tag(kind)
                    }
                }
                LabeledContent("Altezza") {
                    Slider(value: $look.growth, in: Tuning.treeGrowth)
                }
            } footer: {
                Text("Fai clic sui rami per appendere. Pizzica o usa la rotella sull'albero per farlo crescere. Trascina una decorazione fuori dall'albero per toglierla.")
                    .foregroundStyle(Quaderno.inkMuted.color)
            }
            if let focus, look.decorations.indices.contains(focus) {
                Section(look.decorations[focus].kind.name) {
                    LabeledContent("Dimensione") {
                        Slider(value: $look.decorations[focus].scale, in: Tuning.decorationScale)
                    }
                    LabeledContent("Rotazione") {
                        Slider(value: degrees(focus), in: -180...180)
                    }
                    Button("Togli la decorazione", role: .destructive) {
                        look.remove(focus)
                        self.focus = nil
                    }
                }
            }
            Section {
                Button("Taglia l'albero", role: .destructive, action: cut)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .scrollDisabled(true)
        .background(Quaderno.paper.color)
        .tint(Quaderno.ink.color)
        .frame(width: Quaderno.gridCell * 14)
        .fixedSize(horizontal: false, vertical: true)
        .onChange(of: look) { apply(look) }
    }

    /// La rotazione in gradi, per il cursore: nel modello è in radianti.
    private func degrees(_ index: Int) -> Binding<CGFloat> {
        Binding {
            look.decorations[index].rotation * 180 / .pi
        } set: {
            look.decorations[index].rotation = $0 * .pi / 180
        }
    }
}

#Preview("Chiaro") {
    var look = TreeLook()
    look.hang(at: CGPoint(x: 0, y: 30))
    return TreeCard(look: look, focus: 0, apply: { _ in }, cut: {})
        .preferredColorScheme(.light)
}

#Preview("Scuro") {
    TreeCard(look: TreeLook(), focus: nil, apply: { _ in }, cut: {})
        .preferredColorScheme(.dark)
}
