import SbuKit
import SwiftUI

/// The one-tap ideas: a tap adds the Sessione with its hours, to change later in its sheet.
struct SessionIdeas: View {
    let ideas: [BlockSession]
    let add: (BlockSession) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: SbuTheme.space3) {
            Text("Idee")
                .font(SbuTheme.footnote)
                .foregroundStyle(SbuTheme.inkMuted)
                .accessibilityAddTraits(.isHeader)
            SbuListCard(ideas) { idea in
                Button {
                    add(idea)
                } label: {
                    HStack(spacing: SbuTheme.space3) {
                        Text(idea.name)
                        Spacer()
                        Text(idea.hours)
                            .monospacedDigit()
                            .foregroundStyle(SbuTheme.inkMuted)
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityHint("Aggiunge la Sessione")
            }
        }
    }
}

#Preview("Light") {
    SessionIdeas(ideas: BlockSession.presets) { _ in }
        .padding()
}

#Preview("Dark") {
    SessionIdeas(ideas: BlockSession.presets) { _ in }
        .padding()
        .preferredColorScheme(.dark)
}
