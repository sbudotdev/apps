import SbuKit
import SwiftUI

/// One line of the welcome: a symbol, a short title and a sentence.
struct WelcomeStep: View {
    let symbol: String
    let title: LocalizedStringKey
    let text: LocalizedStringKey

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: SbuTheme.space3) {
            Image(systemName: symbol)
                .fontWeight(.medium)
                .foregroundStyle(SbuTheme.ink)
                .frame(width: SbuTheme.space5)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: SbuTheme.space1) {
                Text(title)
                    .font(SbuTheme.headline)
                Text(text)
                    .font(SbuTheme.body)
                    .foregroundStyle(SbuTheme.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("Light") {
    WelcomeStep(symbol: "keyboard", title: "Un suono a ogni tasto", text: "In ogni app.")
        .padding()
}

#Preview("Dark") {
    WelcomeStep(symbol: "keyboard", title: "Un suono a ogni tasto", text: "In ogni app.")
        .padding()
        .preferredColorScheme(.dark)
}
