import SbuKit
import SwiftUI

/// The list of vehicles in settings.
struct VehiclesView: View {
    let store: AppStore
    @State private var editing: Vehicle?
    @State private var isAdding = false

    var body: some View {
        List {
            ForEach(store.state.vehicles) { vehicle in
                Button {
                    editing = vehicle
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(vehicle.nickname).foregroundStyle(SbuTheme.ink)
                            Text(Self.summary(vehicle)).font(SbuTheme.footnote).foregroundStyle(SbuTheme.inkMuted)
                        }
                    } icon: {
                        Image(systemName: vehicle.kind.symbol).foregroundStyle(SbuTheme.ink)
                    }
                }
                .swipeActions {
                    Button("Elimina", role: .destructive) { store.delete(vehicle) }
                }
            }
            Button("Aggiungi veicolo", systemImage: "plus") { isAdding = true }
        }
        .navigationTitle("I tuoi veicoli")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editing) { VehicleWizard(store: store, editing: $0) }
        .sheet(isPresented: $isAdding) { VehicleWizard(store: store) }
    }

    static func summary(_ vehicle: Vehicle) -> String {
        [String(localized: vehicle.kind.title), String(localized: vehicle.fuel.title), vehicle.euro?.title]
            .compactMap { $0 }
            .formatted(.list(type: .and, width: .narrow))
    }
}
