import SbuKit
import SwiftUI

/// One of the two shortcuts on the home panel.
struct HomeTile: View {
    let title: LocalizedStringKey
    let symbol: String

    var body: some View {
        VStack(spacing: SbuTheme.space2) {
            Image(systemName: symbol).fontWeight(.medium)
            Text(title).font(SbuTheme.footnote)
        }
        .foregroundStyle(SbuTheme.ink)
        .frame(maxWidth: .infinity, minHeight: 60)
        .padding(.vertical, SbuTheme.space2)
        .background(SbuTheme.paper, in: RoundedRectangle(cornerRadius: SbuTheme.radiusCard))
        .overlay(RoundedRectangle(cornerRadius: SbuTheme.radiusCard).strokeBorder(SbuTheme.line))
    }
}

#Preview("Light") {
    HomeTile(title: "ZTL", symbol: "map").padding()
}

#Preview("Dark") {
    HomeTile(title: "ZTL", symbol: "map").padding().preferredColorScheme(.dark)
}
