import SbuKit
import SwiftUI

/// The Intenzioni in Home, and the way to add one while there is room. With none yet, one
/// sentence says what an Intenzione is for.
struct IntentionList: View {
    let intentions: [Intention]
    let edit: (Intention) -> Void
    let add: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: SbuTheme.space3) {
            Text("Intenzioni")
                .font(SbuTheme.footnote)
                .foregroundStyle(SbuTheme.inkMuted)
                .accessibilityAddTraits(.isHeader)
            if intentions.isEmpty {
                Text("Scegli un'app da limitare: la apri solo le volte che decidi.")
                    .font(SbuTheme.body)
                    .foregroundStyle(SbuTheme.ink)
            } else {
                SbuListCard(intentions) { intention in
                    IntentionRow(intention: intention) { edit(intention) }
                }
            }
            if intentions.count < ShieldSettings.maxIntentions {
                Button("Aggiungi un'Intenzione", action: add)
                    .font(SbuTheme.body)
            }
        }
    }
}

#Preview("Light") {
    IntentionList(intentions: ShieldSettings.sample().intentions, edit: { _ in }, add: {})
        .padding()
}

#Preview("Dark") {
    IntentionList(intentions: [], edit: { _ in }, add: {})
        .padding()
        .preferredColorScheme(.dark)
}
