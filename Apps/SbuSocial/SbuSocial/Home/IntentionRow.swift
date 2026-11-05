import SbuKit
import SwiftUI

/// One Intenzione in Home: the app and today's openings out of the ones you gave yourself.
/// A tap opens its sheet.
struct IntentionRow: View {
    let intention: Intention
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: SbuTheme.space3) {
                AppLabel(intention: intention)
                Spacer()
                Text("Aperture: \(intention.opens(on: Day(.now))) su \(intention.maxOpens)")
                    .monospacedDigit()
                    .foregroundStyle(SbuTheme.inkMuted)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

#Preview("Light") {
    IntentionRow(intention: Intention(name: "Instagram", opensDay: Day(.now), opens: 3)) {}
        .padding()
}

#Preview("Dark") {
    IntentionRow(intention: Intention(name: "Instagram", opensDay: Day(.now), opens: 3)) {}
        .padding()
        .preferredColorScheme(.dark)
}
