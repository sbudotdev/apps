import SbuKit
import SwiftUI

/// One Sessione: its name and hours, and whether it is on. A tap opens its sheet.
struct SessionRow: View {
    let session: BlockSession
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: SbuTheme.space3) {
                VStack(alignment: .leading, spacing: SbuTheme.space1) {
                    Text(session.name)
                    Text(session.hours)
                        .font(SbuTheme.footnote)
                        .monospacedDigit()
                        .foregroundStyle(SbuTheme.inkMuted)
                }
                Spacer()
                SbuRowMark(filled: session.isOn)
                (session.isOn ? Text("Accesa") : Text("Spenta"))
                    .foregroundStyle(SbuTheme.inkMuted)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

#Preview("Light") {
    SessionRow(session: BlockSession.presets[0]) {}
        .padding()
}

#Preview("Dark") {
    SessionRow(session: BlockSession.presets[2]) {}
        .padding()
        .preferredColorScheme(.dark)
}
