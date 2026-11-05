import SbuKit
import SwiftUI

/// A quest task you open: how yesterday went, or the tip of the day. "Fatto" ticks it.
struct QuestSheet: View {
    @Environment(ShieldModel.self) private var shield
    @Environment(\.dismiss) private var dismiss
    let task: QuestTask

    private var text: String {
        let today = Day(.now)
        let yesterday = Day(ordinal: today.ordinal - 1)
        guard task == .review else { return Tips.text(for: today) }
        if shield.tally.overGoalDays.contains(yesterday) {
            return String(localized: "Ieri hai raggiunto l'Obiettivo giornaliero: il giorno non ha contato per la serie.")
        }
        if shield.tally.exceededDays.contains(yesterday) {
            return String(localized: "Ieri hai aperto un'app oltre le aperture della sua Intenzione: il giorno non ha contato per la serie.")
        }
        if shield.tally.isKept(yesterday, today: today) {
            return String(localized: "Ieri hai tenuto: nessuna Intenzione oltre le sue aperture, e sotto l'Obiettivo giornaliero.")
        }
        return String(localized: "Ieri la serie non era ancora iniziata. Comincia oggi.")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(text)
                    .font(SbuTheme.body)
                    .foregroundStyle(SbuTheme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(SbuTheme.space4)
            }
            .navigationTitle(Text(task.title))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fatto", action: finish)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func finish() {
        shield.complete(task)
        dismiss()
    }
}

#Preview("Light") {
    QuestSheet(task: .tip)
        .environment(ShieldModel(defaults: UserDefaults(suiteName: "preview")!, isDemo: true))
}

#Preview("Dark") {
    QuestSheet(task: .review)
        .environment(ShieldModel(defaults: UserDefaults(suiteName: "preview")!, isDemo: true))
        .preferredColorScheme(.dark)
}
