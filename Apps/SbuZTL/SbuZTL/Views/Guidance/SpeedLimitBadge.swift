import SbuKit
import SwiftUI

/// The limit, drawn like the road sign: a color with a number, so never color alone.
struct SpeedLimitBadge: View {
    let kph: Int

    var body: some View {
        Text(kph, format: .number)
            .font(SbuTheme.headline)
            .foregroundStyle(SbuTheme.ink)
            .frame(minWidth: 44, minHeight: 44)
            .background(SbuTheme.surfaceRaised, in: Circle())
            .overlay(Circle().strokeBorder(SbuTheme.danger, lineWidth: 4))
            .accessibilityLabel(Text("Limite \(kph) chilometri orari"))
    }
}

#Preview("Light") {
    SpeedLimitBadge(kph: 50).padding()
}

#Preview("Dark") {
    SpeedLimitBadge(kph: 50).padding().preferredColorScheme(.dark)
}
