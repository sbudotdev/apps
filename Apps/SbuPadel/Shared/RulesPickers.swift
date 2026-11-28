import SbuKit
import SwiftUI

/// The rule at 40 all and the pair that serves first: chosen before the first point.
/// On the iPhone each one is a segmented control under its own visible label; on the watch they
/// are rows of the controls list, which show their label already.
struct RulesPickers: View {
    let board: Scoreboard

    var body: some View {
        #if os(iOS)
        VStack(alignment: .leading, spacing: SbuTheme.space3) {
            labeled("Al 40 pari") { deucePicker }
            labeled("Serve per prima") { serverPicker }
        }
        .pickerStyle(.segmented)
        .disabled(board.match.hasStarted)
        #else
        Group {
            deucePicker
            serverPicker
        }
        .disabled(board.match.hasStarted)
        #endif
    }

    private var deucePicker: some View {
        Picker("Al 40 pari", selection: Binding(get: { board.match.deuceRule }, set: board.setDeuceRule)) {
            Text("Punto d'oro").tag(DeuceRule.goldenPoint)
            Text("Vantaggi").tag(DeuceRule.advantages)
        }
    }

    private var serverPicker: some View {
        Picker("Serve per prima", selection: Binding(get: { board.match.firstServer }, set: board.setFirstServer)) {
            ForEach(Side.allCases, id: \.self) { side in
                Text(side.name).tag(side)
            }
        }
    }

    #if os(iOS)
    private func labeled(_ title: LocalizedStringKey, @ViewBuilder picker: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: SbuTheme.space1) {
            Text(title)
                .font(SbuTheme.caption)
                .textCase(.uppercase)
                .tracking(SbuTheme.captionTracking)
                .foregroundStyle(SbuTheme.inkMuted)
                .accessibilityHidden(true)
            picker()
                .labelsHidden()
        }
    }
    #endif
}
