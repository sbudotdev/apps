import SbuKit
import SwiftUI

/// The Sessioni tab: how many are on, each one, the one-tap ideas and the App consentite.
struct SessionsView: View {
    @Environment(ShieldModel.self) private var shield
    @State private var editing: BlockSession?

    private var sessions: [BlockSession] { shield.settings.sessions }

    /// The ideas not added yet, by name: an idea you renamed comes back as an idea.
    private var ideas: [BlockSession] {
        BlockSession.presets.filter { idea in !sessions.contains { $0.name == idea.name } }
    }

    private var hasRoom: Bool { sessions.count < ShieldSettings.maxSessions }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SbuTheme.space6) {
                SbuScreenTitle("Sessioni", cartiglio: Cartiglio.today)
                SbuFigure(value: sessions.count(where: \.isOn).formatted(),
                          fullStop: sessions.contains { $0.isRunning(at: .now) } ? .set : .waiting,
                          context: Text("Sessioni accese"))
                VStack(alignment: .leading, spacing: SbuTheme.space3) {
                    if !sessions.isEmpty {
                        SbuListCard(sessions) { session in
                            SessionRow(session: session) { editing = session }
                        }
                    }
                    if hasRoom {
                        Button("Nuova Sessione", action: add)
                            .font(SbuTheme.body)
                    }
                }
                if hasRoom, !ideas.isEmpty {
                    SessionIdeas(ideas: ideas, add: add)
                }
                AllowListCard(shield: shield)
            }
            .padding(SbuTheme.space4)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .sbuPaper(grid: true)
        .sheet(item: $editing) { session in
            SessionForm(session: session)
        }
    }

    private func add() {
        editing = BlockSession(name: "", start: 9 * 60, end: 10 * 60)
    }

    /// Screen Time is asked for when the first Sessione is added, never earlier.
    private func add(_ idea: BlockSession) {
        Task {
            guard await shield.authorize() else { return }
            shield.save(idea)
        }
    }
}

#Preview("Light") {
    NavigationStack {
        SessionsView()
    }
    .environment(ShieldModel(defaults: UserDefaults(suiteName: "preview")!, isDemo: true))
}

#Preview("Dark") {
    NavigationStack {
        SessionsView()
    }
    .environment(ShieldModel(defaults: UserDefaults(suiteName: "preview")!, isDemo: true))
    .preferredColorScheme(.dark)
}
