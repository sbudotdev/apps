import FamilyControls
import SwiftUI

/// An Intenzione's app: its icon and name as Screen Time draws them, or the name alone when
/// there is no real app, as in screenshots.
struct AppLabel: View {
    let intention: Intention

    var body: some View {
        if let app = intention.app {
            Label(app)
        } else {
            Text(intention.name ?? String(localized: "Scegli l'app"))
        }
    }
}

#Preview("Light") {
    AppLabel(intention: Intention(name: "Instagram"))
        .padding()
}

#Preview("Dark") {
    AppLabel(intention: Intention())
        .padding()
        .preferredColorScheme(.dark)
}
