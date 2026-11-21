import SbuKit
import SwiftUI

/// The script's cues: choosing one jumps the prompter there.
struct CueListSheet: View {
    let titles: [String?]
    let current: Int?
    let onJump: (Int) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(titles.indices, id: \.self) { index in
                Button {
                    onJump(index)
                } label: {
                    HStack {
                        Text(CueTitle.text(titles[index], index: index))
                            .foregroundStyle(SbuTheme.ink)
                        Spacer()
                        if index == current {
                            Image(systemName: "checkmark")
                                .foregroundStyle(SbuTheme.ink)
                                .accessibilityLabel(Text("In lettura"))
                        }
                    }
                }
                .accessibilityIdentifier("cue")
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Sezioni")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Chiudi") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview("Light") {
    CueListSheet(titles: ["Apertura", nil, "Saluti"], current: 1) { _ in }
}

#Preview("Dark") {
    CueListSheet(titles: ["Apertura", nil, "Saluti"], current: 1) { _ in }
        .preferredColorScheme(.dark)
}
