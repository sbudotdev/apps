import SbuKit
import SwiftUI

/// What a setup step lets you set: the same controls the app has for it afterwards.
struct SetupStepControl: View {
    let step: SetupStep
    let shield: ShieldModel
    let edit: (Intention) -> Void

    /// The ideas not added yet, as in the Sessioni tab.
    private var ideas: [BlockSession] {
        BlockSession.presets.filter { idea in !shield.settings.sessions.contains { $0.name == idea.name } }
    }

    var body: some View {
        switch step {
        case .access:
            if shield.isAuthorized {
                Text("Accesso concesso.")
                    .font(SbuTheme.body)
                    .foregroundStyle(SbuTheme.inkMuted)
            } else {
                Button("Concedi l'accesso a Tempo di utilizzo", action: ask)
                    .font(SbuTheme.body)
            }
        case .goal:
            GoalStepper(shield: shield)
                .font(SbuTheme.body)
        case .intention:
            IntentionList(intentions: shield.settings.intentions, edit: edit) { edit(Intention()) }
        case .session:
            VStack(alignment: .leading, spacing: SbuTheme.space3) {
                Text("Sessioni accese: \(shield.settings.sessions.count(where: \.isOn))")
                    .font(SbuTheme.body)
                    .monospacedDigit()
                SessionIdeas(ideas: ideas, add: add)
            }
        case .allowed:
            AllowListCard(shield: shield)
        case .widget:
            EmptyView()
        }
    }

    private func ask() {
        Task { _ = await shield.authorize() }
    }

    private func add(_ idea: BlockSession) {
        Task {
            guard await shield.authorize() else { return }
            shield.save(idea)
        }
    }
}

#Preview("Light") {
    SetupStepControl(step: .session, shield: ShieldModel(defaults: UserDefaults(suiteName: "preview")!, isDemo: true)) { _ in }
        .padding()
}

#Preview("Dark") {
    SetupStepControl(step: .goal, shield: ShieldModel(defaults: UserDefaults(suiteName: "preview")!, isDemo: true)) { _ in }
        .padding()
        .preferredColorScheme(.dark)
}
