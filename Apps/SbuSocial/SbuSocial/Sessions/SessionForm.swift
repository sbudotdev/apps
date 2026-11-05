import SbuKit
import SwiftUI

/// A Sessione's sheet: its name, the hours it blocks between, the days, and whether it is on.
struct SessionForm: View {
    @Environment(ShieldModel.self) private var shield
    @Environment(\.dismiss) private var dismiss
    @State private var session: BlockSession

    private var isNew: Bool {
        !shield.settings.sessions.contains { $0.id == session.id }
    }

    private var canSave: Bool {
        session.isValid && !session.name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    init(session: BlockSession) {
        _session = State(initialValue: session)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nome", text: $session.name)
                }
                Section {
                    DatePicker("Inizio", selection: $session.startDate, displayedComponents: .hourAndMinute)
                    DatePicker("Fine", selection: $session.endDate, displayedComponents: .hourAndMinute)
                } footer: {
                    if !session.isValid {
                        Text("Una Sessione dura almeno \(BlockSession.minimumMinutes) minuti.")
                    }
                }
                Section {
                    WeekdaysPicker(days: $session.days)
                }
                if !isNew {
                    Section {
                        Toggle("Accesa", isOn: $session.isOn)
                    }
                    Section {
                        SbuButton("Elimina la Sessione", kind: .destructive, action: remove)
                    }
                }
            }
            .navigationTitle(isNew ? Text("Nuova Sessione") : Text("Sessione"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva", action: save)
                        .disabled(!canSave)
                }
            }
        }
    }

    /// Screen Time is asked for when the first Sessione is saved, never earlier.
    private func save() {
        Task {
            guard await shield.authorize() else { return }
            shield.save(session)
            dismiss()
        }
    }

    private func remove() {
        shield.remove(session)
        dismiss()
    }
}

#Preview("Light") {
    SessionForm(session: BlockSession.presets[0])
        .environment(ShieldModel(defaults: UserDefaults(suiteName: "preview")!, isDemo: true))
}

#Preview("Dark") {
    SessionForm(session: BlockSession.presets[2])
        .environment(ShieldModel(defaults: UserDefaults(suiteName: "preview")!, isDemo: true))
        .preferredColorScheme(.dark)
}
