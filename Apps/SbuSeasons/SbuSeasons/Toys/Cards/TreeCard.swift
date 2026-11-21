import SwiftUI

/// La scheda dell'albero: che cosa appende il prossimo clic sui rami, quanto è alto, e il taglio.
/// Aperta su una decorazione (`ChristmasTree.cardFocus`), anche la sua grandezza, la rotazione e "Togli".
/// Modifica l'albero vivo, un campo per volta: le decorazioni appese mentre è aperta restano (SBU-184).
struct TreeCard: View {
    @Bindable var tree: ChristmasTree
    let cut: () -> Void
    /// «Manda…»: l'albero, con le decorazioni, diventa un file da mandare (SBU-200).
    var send: () -> Void = {}

    var body: some View {
        Form {
            Section {
                Picker("Appendi", selection: $tree.look.hanging) {
                    ForEach(DecorationKind.allCases, id: \.self) { kind in
                        Text(kind.title).tag(kind)
                    }
                }
                LabeledContent("Altezza") {
                    Slider(value: $tree.look.growth, in: Tuning.treeGrowth)
                }
            } footer: {
                Text("Fai clic sui rami per appendere. Pizzica o usa la rotella sull'albero per farlo crescere. Trascina una decorazione fuori dall'albero per toglierla.")
                    .foregroundStyle(Quaderno.inkMuted.color)
            }
            if let focus = tree.cardFocus, tree.look.decorations.indices.contains(focus) {
                Section(tree.look.decorations[focus].kind.name) {
                    LabeledContent("Dimensione") {
                        Slider(value: decoration(focus, \.scale), in: Tuning.decorationScale)
                    }
                    LabeledContent("Rotazione") {
                        Slider(value: degrees(focus), in: -180...180)
                    }
                    Button("Togli la decorazione", role: .destructive) {
                        tree.look.remove(focus)
                    }
                }
            }
            Section {
                Button("Manda…", action: send)
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
    }

    /// Un campo della decorazione `index`, se c'è ancora: l'albero può perderla mentre la scheda è aperta.
    private func decoration(_ index: Int, _ field: WritableKeyPath<Decoration, CGFloat>) -> Binding<CGFloat> {
        Binding {
            tree.look.decorations.indices.contains(index) ? tree.look.decorations[index][keyPath: field] : 0
        } set: {
            guard tree.look.decorations.indices.contains(index) else { return }
            tree.look.decorations[index][keyPath: field] = $0
        }
    }

    /// La rotazione in gradi, per il cursore: nel modello è in radianti.
    private func degrees(_ index: Int) -> Binding<CGFloat> {
        let radians = decoration(index, \.rotation)
        return Binding { radians.wrappedValue * 180 / .pi } set: { radians.wrappedValue = $0 * .pi / 180 }
    }
}

#Preview("Chiaro") {
    let tree = ChristmasTree(at: .zero)
    tree.clicked(at: CGPoint(x: 0, y: 30))
    tree.cardFocus = 0
    return TreeCard(tree: tree, cut: {})
        .preferredColorScheme(.light)
}

#Preview("Scuro") {
    TreeCard(tree: ChristmasTree(at: .zero), cut: {})
        .preferredColorScheme(.dark)
}
