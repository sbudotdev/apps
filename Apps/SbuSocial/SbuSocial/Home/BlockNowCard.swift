import SbuKit
import SwiftUI

/// Blocca ora: every app but the allowed ones closes now for the time you pick.
struct BlockNowCard: View {
    let shield: ShieldModel

    var body: some View {
        VStack(alignment: .leading, spacing: SbuTheme.space2) {
            if let end = shield.blockNowEnd {
                Text("Blocco fino alle \(end, format: .dateTime.hour().minute())")
                Button("Termina il blocco", action: shield.endBlockNow)
            } else {
                Menu("Blocca ora") {
                    ForEach(ShieldSettings.blockNowLengths, id: \.self) { minutes in
                        Button {
                            start(minutes: minutes)
                        } label: {
                            Text(Duration.seconds(minutes * 60), format: .units(allowed: [.hours, .minutes], width: .wide))
                        }
                    }
                }
                Text("Tutte le app si chiudono per il tempo che scegli, tranne le App consentite.")
                    .font(SbuTheme.footnote)
                    .foregroundStyle(SbuTheme.inkMuted)
            }
        }
        .font(SbuTheme.body)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(SbuTheme.space4)
        .background(SbuTheme.surfaceRaised, in: .rect(cornerRadius: SbuTheme.radiusCard))
        .overlay {
            RoundedRectangle(cornerRadius: SbuTheme.radiusCard)
                .strokeBorder(SbuTheme.line, lineWidth: SbuTheme.hairline)
        }
    }

    /// Screen Time is asked for the first time you block, never earlier.
    private func start(minutes: Int) {
        Task {
            guard await shield.authorize() else { return }
            shield.startBlockNow(minutes: minutes)
        }
    }
}

#Preview("Light") {
    BlockNowCard(shield: ShieldModel(defaults: UserDefaults(suiteName: "preview")!))
        .padding()
}

#Preview("Dark") {
    BlockNowCard(shield: ShieldModel(defaults: UserDefaults(suiteName: "preview")!))
        .padding()
        .preferredColorScheme(.dark)
}
