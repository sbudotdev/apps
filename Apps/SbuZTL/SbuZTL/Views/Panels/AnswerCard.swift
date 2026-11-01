import SbuKit
import SwiftUI

/// The answer: a word, a symbol, why. The full stop is set only when the sources settle it.
struct AnswerCard: View {
    let headline: LocalizedStringKey
    let detail: LocalizedStringResource
    let tint: Color
    let symbol: String
    let isCertain: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: SbuTheme.space1) {
            HStack(alignment: .firstTextBaseline, spacing: SbuTheme.space2) {
                Image(systemName: symbol).fontWeight(.medium).foregroundStyle(tint)
                Text(headline).font(SbuTheme.headline).foregroundStyle(SbuTheme.ink)
                SbuFullStop(isCertain ? .set : .waiting, size: .mark)
            }
            Text(detail).font(SbuTheme.footnote).foregroundStyle(SbuTheme.inkMuted)
        }
        .padding(SbuTheme.space3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SbuTheme.paper, in: RoundedRectangle(cornerRadius: SbuTheme.radiusCard))
        .overlay(RoundedRectangle(cornerRadius: SbuTheme.radiusCard).strokeBorder(tint))
        .accessibilityElement(children: .combine)
    }
}

#Preview("Light") {
    AnswerCard(headline: "Non puoi entrare", detail: "Vietata a questa classe Euro.", tint: SbuTheme.danger, symbol: "minus.circle", isCertain: true).padding()
}

#Preview("Dark") {
    AnswerCard(headline: "Non lo so", detail: "Segui la segnaletica.", tint: SbuTheme.warning, symbol: "questionmark.circle", isCertain: false).padding().preferredColorScheme(.dark)
}
