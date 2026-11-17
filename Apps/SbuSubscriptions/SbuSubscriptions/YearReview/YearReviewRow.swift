import SbuKit
import SwiftUI

/// The way into the year review, at the top of the home from 1 December to 15 January, until you close it.
struct YearReviewRow: View {
    let year: Int
    let open: () -> Void
    let close: () -> Void

    var body: some View {
        HStack(spacing: SbuTheme.space3) {
            Button(action: open) {
                Label("Il tuo \(year) in abbonamenti", systemImage: "calendar")
                    .foregroundStyle(SbuTheme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(.rect)
            }
            .accessibilityIdentifier("yearReview")
            Button("Nascondi il riepilogo", systemImage: "xmark", action: close)
                .labelStyle(.iconOnly)
                .foregroundStyle(SbuTheme.inkMuted)
                .accessibilityIdentifier("closeYearReview")
        }
        // Two buttons in one row: each takes only its own taps.
        .buttonStyle(.borderless)
    }
}

#Preview("Light") {
    List { YearReviewRow(year: 2026, open: {}, close: {}) }
}

#Preview("Dark") {
    List { YearReviewRow(year: 2026, open: {}, close: {}) }
        .preferredColorScheme(.dark)
}
