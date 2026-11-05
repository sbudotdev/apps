import SbuKit
import SwiftUI

/// The tool screen: the time in a block today, the Serie, Blocca ora, the Intenzioni and the
/// Missione del giorno.
struct HomeView: View {
    @Environment(ShieldModel.self) private var shield
    @State private var editing: Intention?
    @State private var questTask: QuestTask?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SbuTheme.space6) {
                SbuScreenTitle("Home", cartiglio: Cartiglio.today)
                BlockedFigure(tally: shield.tally, isBlocking: shield.settings.isBlocking(now: .now))
                SeriesCard(tally: shield.tally)
                BlockNowCard(shield: shield)
                IntentionList(intentions: shield.settings.intentions, edit: { editing = $0 }, add: add)
                QuestCard(done: shield.tally.quest(on: Day(.now))) { questTask = $0 }
            }
            .padding(SbuTheme.space4)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .sbuPaper(grid: true)
        .sheet(item: $editing) { intention in
            IntentionForm(intention: intention)
        }
        .sheet(item: $questTask) { task in
            QuestSheet(task: task)
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
