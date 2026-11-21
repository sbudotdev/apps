import SwiftUI

/// La letterina a Babbo Natale (SBU-178): scrivi un desiderio e "Spedisci". Il testo resta solo qui, nella finestra:
/// non si salva da nessuna parte e non esce dal Mac. La slitta passa e porta via la busta (`SeasonScene.mailLetter`).
struct LetterView: View {
    @State private var wish = ""
    @FocusState private var writing: Bool
    let send: () -> Void
    let cancel: () -> Void

    var body: some View {
        Form {
            Section {
                TextField("Caro Babbo Natale,", text: $wish, axis: .vertical)
                    .lineLimit(4...8)
                    .focused($writing)
                    .accessibilityLabel(Text("Il tuo desiderio"))
            } footer: {
                Text("Il testo non si salva da nessuna parte: la slitta passa e se lo porta via.")
                    .foregroundStyle(Quaderno.inkMuted.color)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .safeAreaInset(edge: .bottom) {
            HStack {
                Spacer()
                Button("Annulla", role: .cancel, action: cancel)
                    .keyboardShortcut(.cancelAction)
                Button("Spedisci", action: send)
                    .keyboardShortcut(.defaultAction)
                    .disabled(wish.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(Quaderno.space4)
        }
        .background(Quaderno.paper.color)
        .tint(Quaderno.ink.color)
        .frame(width: Quaderno.gridCell * 16)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear { writing = true }
    }
}

#Preview("Chiaro") {
    LetterView(send: {}, cancel: {})
        .preferredColorScheme(.light)
}

#Preview("Scuro") {
    LetterView(send: {}, cancel: {})
        .preferredColorScheme(.dark)
}
