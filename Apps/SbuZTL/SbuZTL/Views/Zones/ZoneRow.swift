import SbuKit
import SwiftUI

/// A zone with its answer.
struct ZoneRow: View {
    let zone: Zone
    let verdict: Verdict

    var body: some View {
        HStack(spacing: SbuTheme.space3) {
            Image(systemName: verdict.access.symbol)
                .fontWeight(.medium)
                .foregroundStyle(verdict.access.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(zone.name).font(SbuTheme.body).foregroundStyle(SbuTheme.ink)
                Text(verdict.access.headline).font(SbuTheme.footnote).foregroundStyle(SbuTheme.inkMuted)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(SbuTheme.footnote).foregroundStyle(SbuTheme.inkMuted)
                .accessibilityHidden(true)
        }
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
