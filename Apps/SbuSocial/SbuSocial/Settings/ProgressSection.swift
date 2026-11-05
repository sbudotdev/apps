import SbuKit
import SwiftUI

/// The Serie and the record in Impostazioni: take back the last broken day, start the record over.
struct ProgressSection: View {
    let shield: ShieldModel

    var body: some View {
        Section {
            Button("Ripristina la serie", action: shield.restoreStreak)
        } footer: {
            Text("Toglie l'ultimo giorno che ha interrotto la serie.")
        }
        Section {
            SbuButton("Azzera il record", kind: .destructive, confirmationTitle: "Azzerare il record del tempo in blocco?", action: shield.resetRecord)
        }
    }
}

#Preview("Light") {
    List {
        ProgressSection(shield: ShieldModel(defaults: UserDefaults(suiteName: "preview")!, isDemo: true))
    }
}

#Preview("Dark") {
    List {
        ProgressSection(shield: ShieldModel(defaults: UserDefaults(suiteName: "preview")!, isDemo: true))
    }
    .preferredColorScheme(.dark)
}
