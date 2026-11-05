import SbuKit
import SwiftUI

/// The first-run setup: one step per thing to set, each asking its permission only when it is
/// used. Every step can be passed over, and the whole setup skipped.
struct SetupView: View {
    @Environment(ShieldModel.self) private var shield
    @State private var step = SetupStep.access
    @State private var editing: Intention?

    private var position: String {
        String(localized: "Sbu · Social · Passo \(step.rawValue + 1) di \(SetupStep.allCases.count)")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SbuTheme.space6) {
                SbuScreenTitle(verbatim: String(localized: step.title), cartiglio: position)
                Text(step.sentence)
                    .font(SbuTheme.body)
                    .foregroundStyle(SbuTheme.ink)
                SetupStepControl(step: step, shield: shield) { editing = $0 }
            }
            .padding(SbuTheme.space4)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .sbuPaper(grid: true)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: SbuTheme.space3) {
                SbuButton(step.next == nil ? "Fatto" : "Avanti", action: advance)
                if step.next != nil {
                    Button("Salta la configurazione", action: shield.finishSetup)
                        .font(SbuTheme.body)
                }
            }
            .padding(SbuTheme.space4)
            .background(SbuTheme.paper)
        }
        .sheet(item: $editing) { intention in
            IntentionForm(intention: intention)
        }
    }

    private func advance() {
        if let next = step.next {
            step = next
        } else {
            shield.finishSetup()
        }
    }
}

#Preview("Light") {
    SetupView()
        .environment(ShieldModel(defaults: UserDefaults(suiteName: "preview")!, isDemo: true))
}

#Preview("Dark") {
    SetupView()
        .environment(ShieldModel(defaults: UserDefaults(suiteName: "preview")!, isDemo: true))
        .preferredColorScheme(.dark)
}
