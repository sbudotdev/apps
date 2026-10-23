import SbuKit
import SwiftUI

/// Contacts saved more than once, as in the Originale: how many would go as the one figure, then
/// one card per person with every copy, and "Unisci" on each. Before merging, the copies are
/// saved as a vCard file in Files, in the Sbu Clean folder.
///
/// Contacts are asked for only here, when the user taps the button: never at launch.
struct ContactsScreen: View {
    let model: ContactsModel

    @Environment(\.openURL) private var openURL
    @State private var merging: [ContactCard]?
    @State private var isConfirming = false
    @State private var isClosing = false

    var body: some View {
        Group {
            switch model.access {
            case .notDetermined:
                EmptyScreen(sentence: "Sbu Clean trova le persone salvate due volte e le unisce in un solo contatto. I contatti restano su questo iPhone.") {
                    Button("Consenti l'accesso ai contatti") {
                        Task { await model.requestAccess() }
                    }
                    .buttonStyle(SbuFieldPillStyle())
                }
            case .denied:
                EmptyScreen(sentence: "Sbu Clean non può vedere i tuoi contatti. Puoi consentirlo in Impostazioni.") {
                    Button("Apri Impostazioni", action: openSettings)
                        .buttonStyle(SbuFieldPillStyle())
                }
            case .allowed:
                if model.hasLoaded && model.groups.isEmpty {
                    EmptyScreen(sentence: "Nessun contatto doppio. Ogni persona è salvata una volta sola.")
                } else {
                    list
                }
            }
        }
        .navigationTitle("Contatti doppi")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await model.load()
        }
        .confirmationDialog("Unire questi contatti?", isPresented: $isConfirming, titleVisibility: .visible, presenting: merging) { group in
            Button("Unisci \(group.count) contatti") {
                Task {
                    if await model.merge(group) != nil {
                        isClosing = true
                    }
                }
            }
        } message: { group in
            Text("Resta \(group.first?.name ?? ""), con tutti i numeri e gli indirizzi. Prima salvo una copia dei \(group.count) contatti in File, nella cartella Sbu Clean.")
        }
        .sbuClosure($isClosing, word: "Uniti")
    }

    private var list: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: SbuTheme.space4) {
                SbuFigure(
                    value: model.duplicateCount.formatted(),
                    fullStop: model.hasLoaded ? .set : .waiting,
                    context: Text("contatti doppi in \(model.groups.count) persone")
                )

                if let failure = model.failure {
                    Label(failure, systemImage: "exclamationmark.triangle")
                        .font(SbuTheme.subheadline)
                        .foregroundStyle(SbuTheme.danger)
                }

                ForEach(model.groups, id: \.first?.id) { group in
                    ContactGroupCard(group: group) {
                        merging = group
                        isConfirming = true
                    }
                }
            }
            .padding(SbuTheme.space4)
        }
        .background(SbuTheme.paper)
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }
}

#Preview("Light") {
    NavigationStack {
        ContactsScreen(model: ContactsModel(store: DemoContactStore()))
    }
    .environment(\.sbuAccent, .clean)
}

#Preview("Dark") {
    NavigationStack {
        ContactsScreen(model: ContactsModel(store: DemoContactStore()))
    }
    .environment(\.sbuAccent, .clean)
    .preferredColorScheme(.dark)
}
