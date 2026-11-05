import SwiftUI

/// The Obiettivo giornaliero, a quarter of an hour at a time.
struct GoalStepper: View {
    @Bindable var shield: ShieldModel

    private var length: String {
        Duration.seconds(shield.goalMinutes * 60).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
    }

    var body: some View {
        Stepper(value: $shield.goalMinutes, in: 15...720, step: 15) {
            Text("Obiettivo giornaliero: \(length)")
        }
    }
}

#Preview("Light") {
    GoalStepper(shield: ShieldModel(defaults: UserDefaults(suiteName: "preview")!, isDemo: true))
        .padding()
}

#Preview("Dark") {
    GoalStepper(shield: ShieldModel(defaults: UserDefaults(suiteName: "preview")!, isDemo: true))
        .padding()
        .preferredColorScheme(.dark)
}
