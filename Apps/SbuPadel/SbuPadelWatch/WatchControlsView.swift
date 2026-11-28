import SbuKit
import SwiftUI

/// The second page: undo, a new match, and the rules before the first point.
struct WatchControlsView: View {
    let board: Scoreboard
    @State private var isConfirmingNewMatch = false

    var body: some View {
        List {
            Button("Annulla punto", systemImage: "arrow.uturn.backward", action: board.undo)
                .disabled(board.match.hasStarted == false)
            Button("Nuova partita", systemImage: "arrow.counterclockwise", role: .destructive) {
                isConfirmingNewMatch = true
            }
            .disabled(board.match.hasStarted == false)
            RulesPickers(board: board)
        }
        .confirmationDialog("Nuova partita", isPresented: $isConfirmingNewMatch, titleVisibility: .visible) {
            Button("Nuova partita", role: .destructive, action: board.newMatch)
        } message: {
            Text("Cancellare il punteggio di questa partita?")
        }
    }
}
