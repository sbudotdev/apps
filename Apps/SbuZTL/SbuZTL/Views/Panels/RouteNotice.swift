import SbuKit
import SwiftUI

/// A caveat on the route: always a word, never only a color.
struct RouteNotice: View {
    let symbol: String
    let title: LocalizedStringKey
    let detail: LocalizedStringKey

    var body: some View {
        HStack(alignment: .top, spacing: SbuTheme.space2) {
            Image(systemName: symbol).fontWeight(.medium).foregroundStyle(SbuTheme.warning)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(SbuTheme.subheadline.weight(.medium)).foregroundStyle(SbuTheme.ink)
                Text(detail).font(SbuTheme.footnote).foregroundStyle(SbuTheme.inkMuted)
            }
        }
        .padding(SbuTheme.space3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SbuTheme.paper, in: RoundedRectangle(cornerRadius: SbuTheme.radiusCard))
        .overlay(RoundedRectangle(cornerRadius: SbuTheme.radiusCard).strokeBorder(SbuTheme.line))
        .accessibilityElement(children: .combine)
    }
}

#Preview("Light") {
    RouteNotice(symbol: "figure.walk", title: "L'arrivo è dentro Area C", detail: "Ti lascio al bordo.").padding()
}

#Preview("Dark") {
    RouteNotice(symbol: "figure.walk", title: "L'arrivo è dentro Area C", detail: "Ti lascio al bordo.").padding().preferredColorScheme(.dark)
}
