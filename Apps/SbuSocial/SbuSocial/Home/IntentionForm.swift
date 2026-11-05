import FamilyControls
import SbuKit
import SwiftUI

/// An Intenzione's sheet: the app, how many openings a day, how long each lasts and on which days.
/// Screen Time is asked for when you choose the app, never earlier.
struct IntentionForm: View {
    @Environment(ShieldModel.self) private var shield
    @Environment(\.dismiss) private var dismiss
    @State private var intention: Intention
    @State private var isPicking = false
    @State private var picked = FamilyActivitySelection()
    @State private var pickProblem: LocalizedStringKey?

    private var isNew: Bool {
        !shield.settings.intentions.contains { $0.id == intention.id }
    }

    init(intention: Intention) {
        _intention = State(initialValue: intention)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button(action: pick) {
                        AppLabel(intention: intention)
                    }
                } footer: {
                    if let pickProblem {
                        Text(pickProblem)
                    }
                }
                Section {
                    Stepper("Aperture al giorno: \(intention.maxOpens)", value: $intention.maxOpens, in: 1...50)
                    Picker("Durata di ogni apertura", selection: $intention.minutes) {
                        ForEach(Intention.lengths, id: \.self) { minutes in
                            Text(Duration.seconds(minutes * 60), format: .units(allowed: [.minutes], width: .wide))
                                .tag(minutes)
                        }
                    }
                }
                Section {
                    WeekdaysPicker(days: $intention.days)
                }
                if !isNew {
                    Section {
                        SbuButton("Elimina l'Intenzione", kind: .destructive, action: remove)
                    }
                }
            }
            .navigationTitle(isNew ? Text("Nuova Intenzione") : Text("Intenzione"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva", action: save)
                        .disabled(isNew && intention.app == nil)
                }
            }
            .familyActivityPicker(isPresented: $isPicking, selection: $picked)
            .onChange(of: isPicking) {
                if !isPicking { take(picked) }
            }
        }
    }

    private func pick() {
        Task {
            guard await shield.authorize() else {
                pickProblem = "Serve l'accesso a Tempo di utilizzo. Dallo in Impostazioni, Tempo di utilizzo."
                return
            }
            picked = FamilyActivitySelection()
            isPicking = true
        }
    }

    /// The system picker lets you choose anything; an Intenzione takes exactly one app.
    private func take(_ selection: FamilyActivitySelection) {
        guard selection != FamilyActivitySelection() else { return }
        guard selection.applicationTokens.count == 1, selection.categoryTokens.isEmpty,
              let app = selection.applicationTokens.first else {
            pickProblem = "Scegli una sola app."
            return
        }
        guard !shield.settings.isLimited(app, besides: intention.id) else {
            pickProblem = "Questa app ha già un'Intenzione."
            return
        }
        pickProblem = nil
        intention.app = app
        intention.name = nil
    }

    private func save() {
        shield.save(intention)
        dismiss()
    }

    private func remove() {
        shield.remove(intention)
        dismiss()
    }
}

#Preview("Light") {
    IntentionForm(intention: Intention(name: "Instagram"))
        .environment(ShieldModel(defaults: UserDefaults(suiteName: "preview")!))
}

#Preview("Dark") {
    IntentionForm(intention: Intention())
        .environment(ShieldModel(defaults: UserDefaults(suiteName: "preview")!))
        .preferredColorScheme(.dark)
}
