import SbuKit
import SwiftUI

/// The tool screen: the time in a block today, Blocca ora and the Intenzioni.
struct HomeView: View {
    @Environment(ShieldModel.self) private var shield
    @State private var editing: Intention?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SbuTheme.space6) {
                SbuScreenTitle("Home", cartiglio: Cartiglio.today)
                BlockedFigure(tally: shield.tally, isBlocking: shield.settings.isBlocking(now: .now))
                BlockNowCard(shield: shield)
                IntentionList(intentions: shield.settings.intentions, edit: { editing = $0 }, add: add)
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
    .environment(ShieldModel(defaults: UserDefaults(suiteName: "preview")!, isDemo: true))
}

#Preview("Dark") {
    NavigationStack {
        HomeView()
    }
    .environment(ShieldModel(defaults: UserDefaults(suiteName: "preview")!, isDemo: true))
    .preferredColorScheme(.dark)
}
