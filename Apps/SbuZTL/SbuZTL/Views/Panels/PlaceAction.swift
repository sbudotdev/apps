import SbuKit
import SwiftUI

/// Save, share, open: the row of small actions.
struct PlaceAction: View {
    let title: LocalizedStringKey
    let symbol: String

    var body: some View {
        VStack(spacing: SbuTheme.space1) {
            Image(systemName: symbol).fontWeight(.medium)
            Text(title).font(SbuTheme.footnote).lineLimit(1).minimumScaleFactor(0.8)
        }
        .foregroundStyle(SbuTheme.ink)
        .frame(maxWidth: .infinity, minHeight: 52)
        .background(SbuTheme.paper, in: RoundedRectangle(cornerRadius: SbuTheme.radiusCard))
        .overlay(RoundedRectangle(cornerRadius: SbuTheme.radiusCard).strokeBorder(SbuTheme.line))
    }
}

#Preview("Light") {
    PlaceAction(title: "Salva", symbol: "bookmark").padding()
}

#Preview("Dark") {
    PlaceAction(title: "Salva", symbol: "bookmark").padding().preferredColorScheme(.dark)
}
