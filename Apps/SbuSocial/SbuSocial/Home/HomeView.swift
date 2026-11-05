import SbuKit
import SwiftUI

/// The tool screen: the Intenzioni and Blocca ora.
struct HomeView: View {
    @Environment(ShieldModel.self) private var shield
    @State private var editing: Intention?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SbuTheme.space6) {
                SbuScreenTitle("Home", cartiglio: Cartiglio.today)
                if shield.settings.intentions.isEmpty {
                    SbuEmpty(sentence: "Scegli un'app da limitare: la apri solo le volte che decidi.") {
                        Button("Scegli un'app", action: add)
                    }
                } else {
                    IntentionList(intentions: shield.settings.intentions, edit: { editing = $0 }, add: add)
                }
                BlockNowCard(shield: shield)
            }
            .padding(SbuTheme.space4)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .sbuPaper(grid: true)
        .sheet(item: $editing) { intention in
            IntentionForm(intention: intention)
        }
    }

    private func add() {
        editing = Intention()
    }
}

#Preview("Light") {
    NavigationStack {
        HomeView()
    }
    .environment(ShieldModel(defaults: UserDefaults(suiteName: "preview")!))
}

#Preview("Dark") {
    NavigationStack {
        HomeView()
    }
    .environment(ShieldModel(defaults: UserDefaults(suiteName: "preview")!))
    .preferredColorScheme(.dark)
}
