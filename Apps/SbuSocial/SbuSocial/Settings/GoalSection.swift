import SbuKit
import SwiftUI

/// The Obiettivo giornaliero in Impostazioni: the screen time you give yourself for a day.
struct GoalSection: View {
    @Bindable var shield: ShieldModel

    private var length: String {
        Duration.seconds(shield.goalMinutes * 60).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
    }

    var body: some View {
        Section {
            Stepper(value: $shield.goalMinutes, in: 15...720, step: 15) {
                Text("Obiettivo giornaliero: \(length)")
            }
        } footer: {
            Text("Il tempo di schermo che ti dai per oggi. Quando lo raggiungi arriva una notifica e il giorno non conta per la serie.")
        }
    }
}

#Preview("Light") {
    List {
        GoalSection(shield: ShieldModel(defaults: UserDefaults(suiteName: "preview")!, isDemo: true))
    }
}

#Preview("Dark") {
    List {
        GoalSection(shield: ShieldModel(defaults: UserDefaults(suiteName: "preview")!, isDemo: true))
    }
    .preferredColorScheme(.dark)
}
