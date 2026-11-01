import SbuKit
import SwiftUI

/// Permits you hold, each for one vehicle and one zone. The app can't verify them.
struct PermitsView: View {
    let store: AppStore
    let catalog: ZoneCatalog
    @State private var isAdding = false

    var body: some View {
        List {
            Section {
                ForEach(store.state.permits) { permit in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(catalog.zones.first { $0.id == permit.zoneID }?.name ?? "")
                        Text(store.state.vehicles.first { $0.id == permit.vehicleID }?.nickname ?? "")
                            .font(SbuTheme.footnote)
                            .foregroundStyle(SbuTheme.inkMuted)
                    }
                }
                .onDelete { store.state.permits.remove(atOffsets: $0) }
                Button("Aggiungi permesso", systemImage: "plus") { isAdding = true }
                    .disabled(!store.hasVehicle)
            } footer: {
                Text("Aggiungi solo i permessi che hai davvero. Non posso verificarli: l'esito per quella zona diventa \"puoi entrare\".")
            }
        }
        .navigationTitle("Permessi")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isAdding) { PermitWizard(store: store, catalog: catalog) }
    }
}
