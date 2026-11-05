import SbuKit
import SwiftUI

/// Screen Time access in Impostazioni: whether it is allowed, and the way to ask again.
struct AccessSection: View {
    let shield: ShieldModel

    var body: some View {
        Section {
            if shield.isAuthorized {
                LabeledContent("Tempo di utilizzo") {
                    Text("Concesso")
                }
            } else {
                Button("Concedi l'accesso a Tempo di utilizzo", action: ask)
            }
        } footer: {
            Text("Serve per coprire le app con lo Schermo e contare il tempo di schermo. I dati restano sul telefono.")
        }
    }

    private func ask() {
        Task { _ = await shield.authorize() }
    }
}

#Preview("Light") {
    List {
        AccessSection(shield: ShieldModel(defaults: UserDefaults(suiteName: "preview")!, isDemo: true))
    }
}

#Preview("Dark") {
    List {
        AccessSection(shield: ShieldModel(defaults: UserDefaults(suiteName: "preview")!, isDemo: true))
    }
    .preferredColorScheme(.dark)
}
