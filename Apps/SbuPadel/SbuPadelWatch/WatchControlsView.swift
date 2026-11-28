import SbuKit
import SwiftUI

/// The second page: a new match, the rules before the first point, and what the workout does.
struct WatchControlsView: View {
    let board: Scoreboard
    let workout: MatchWorkout
    @State private var isConfirmingNewMatch = false

    var body: some View {
        List {
            Section {
                Button("Nuova partita", systemImage: "arrow.counterclockwise", role: .destructive) {
                    isConfirmingNewMatch = true
                }
                .disabled(board.match.hasStarted == false)
            }
            Section {
                RulesPickers(board: board)
            } header: {
                Text("Regole")
            } footer: {
                Text(board.match.hasStarted ? "Le regole le scegli prima del primo punto." : "Valgono dal primo punto.")
            }
            Section {
                Label(workout.isRunning ? "Allenamento in corso" : "Nessun allenamento", systemImage: "heart")
                    .foregroundStyle(SbuTheme.inkMuted)
            } footer: {
                Text("Dal primo all'ultimo punto la partita è un allenamento di tennis in Salute, così Sbu Padel resta sullo schermo.")
            }
        }
        .confirmationDialog("Nuova partita", isPresented: $isConfirmingNewMatch, titleVisibility: .visible) {
            Button("Nuova partita", role: .destructive, action: board.newMatch)
        } message: {
            Text("Cancellare il punteggio di questa partita?")
        }
    }
}

#Preview("Light") {
    WatchControlsView(board: Scoreboard(defaults: UserDefaults(suiteName: "preview")!), workout: MatchWorkout())
}

#Preview("Dark") {
    WatchControlsView(board: Scoreboard(defaults: UserDefaults(suiteName: "preview")!), workout: MatchWorkout())
        .preferredColorScheme(.dark)
}
