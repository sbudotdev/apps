import SbuKit
import SwiftUI

/// The first screen: the one thing to do. No carousel, no permission asked (design system).
struct FirstRunView: View {
    let onAdd: () -> Void
    let onLater: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: SbuTheme.space4) {
            Spacer()
            SbuEmpty(sentence: "Aggiungi la tua auto per sapere dove puoi entrare, e quando.") {
                SbuButton("Aggiungi il veicolo", action: onAdd)
                    .accessibilityIdentifier("addVehicle")
            }
            SbuButton("Più tardi", kind: .secondary, action: onLater)
                .accessibilityIdentifier("later")
            Spacer()
        }
        .padding(SbuTheme.space4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sbuPaper(grid: true)
    }
}

#Preview("Light") {
    FirstRunView(onAdd: {}, onLater: {})
}

#Preview("Dark") {
    FirstRunView(onAdd: {}, onLater: {}).preferredColorScheme(.dark)
}
