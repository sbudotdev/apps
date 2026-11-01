import SbuKit
import SwiftUI

/// A symbol with a 44 pt hit area; `isPill` gives it the look of the map controls.
struct IconButton: View {
    let title: LocalizedStringKey
    let symbol: String
    var isPill = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isPill {
                    Image(systemName: symbol).fontWeight(.medium).mapPill()
                } else {
                    Image(systemName: symbol).fontWeight(.medium).frame(width: 44, height: 44)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(SbuTheme.ink)
        .accessibilityLabel(Text(title))
    }
}

#Preview("Light") {
    IconButton(title: "Chiudi", symbol: "xmark") {}.padding()
}

#Preview("Dark") {
    IconButton(title: "Chiudi", symbol: "xmark", isPill: true) {}.padding().preferredColorScheme(.dark)
}
