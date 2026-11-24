import SbuKit
import SwiftUI

struct LibraryRow: View {
    let script: Script
    let isActive: Bool

    /// Whitespace-separated words: close enough for a reading time, and cheap for a long list.
    private var wordCount: Int {
        script.body.split(whereSeparator: \.isWhitespace).count { !$0.hasPrefix("#") && !$0.allSatisfy { "-*_=".contains($0) } }
    }

    var body: some View {
        HStack(spacing: SbuTheme.space2) {
            VStack(alignment: .leading, spacing: SbuTheme.space1) {
                Text(script.title.isEmpty ? String(localized: "Senza titolo") : script.title)
                    .font(SbuTheme.headline)
                    .lineLimit(1)
                Text("\(ReadingTime.text(words: wordCount)) · \(script.updatedAt, format: .dateTime.day().month().hour().minute())")
                    .font(SbuTheme.caption)
                    .monospacedDigit()
                    .foregroundStyle(SbuTheme.inkMuted)
            }
            Spacer()
            if isActive {
                // The one colored mark: the script in the prompter now.
                SbuFullStop(.set, size: .mark)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, SbuTheme.space1)
        .accessibilityElement(children: .combine)
        .accessibilityValue(isActive ? Text("Nel prompter") : Text(verbatim: ""))
    }
}
