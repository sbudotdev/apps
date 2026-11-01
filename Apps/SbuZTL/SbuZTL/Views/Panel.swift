import SbuKit
import SwiftUI

/// The sheet at the bottom of the map. Not a system sheet: it lives with the map, under the shell's settings.
struct Panel<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: SbuTheme.space4) {
            content
        }
        .padding(SbuTheme.space4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SbuTheme.surfaceRaised, in: UnevenRoundedRectangle(topLeadingRadius: SbuTheme.radiusSheet, topTrailingRadius: SbuTheme.radiusSheet))
        .background(alignment: .bottom) {
            // Fills the strip under the home indicator.
            SbuTheme.surfaceRaised.frame(height: SbuTheme.space12).ignoresSafeArea(edges: .bottom)
        }
    }
}

#Preview("Light") {
    Panel { Text("Pannello") }
}

#Preview("Dark") {
    Panel { Text("Pannello") }
        .preferredColorScheme(.dark)
}
