import SwiftUI

/// The rule at 40 all and the pair that serves first: chosen before the first point.
struct RulesPickers: View {
    let board: Scoreboard

    var body: some View {
        Group {
            Picker("Al 40 pari", selection: Binding(get: { board.match.deuceRule }, set: board.setDeuceRule)) {
                Text("Punto d'oro").tag(DeuceRule.goldenPoint)
                Text("Vantaggi").tag(DeuceRule.advantages)
            }
            Picker("Serve per prima", selection: Binding(get: { board.match.firstServer }, set: board.setFirstServer)) {
                Text("Noi").tag(Side.us)
                Text("Loro").tag(Side.them)
            }
        }
        .disabled(board.match.hasStarted)
    }
}
