import SbuKit
import SwiftUI

/// Choose a vehicle, then a zone.
struct PermitWizard: View {
    @Environment(\.dismiss) private var dismiss
    let store: AppStore
    let catalog: ZoneCatalog
    @State private var vehicle: Vehicle?
    @State private var query = ""

    private var zones: [Zone] {
        let sorted = catalog.zones.sorted { ($0.city.name, $0.name) < ($1.city.name, $1.name) }
        return query.isEmpty ? sorted : sorted.filter { $0.name.localizedStandardContains(query) || $0.city.name.localizedStandardContains(query) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if let vehicle {
                    List(zones) { zone in
                        Button {
                            store.state.permits.append(Permit(vehicleID: vehicle.id, zoneID: zone.id))
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(zone.name).foregroundStyle(SbuTheme.ink)
                                Text(zone.city.name).font(SbuTheme.footnote).foregroundStyle(SbuTheme.inkMuted)
                            }
                        }
                    }
                    .searchable(text: $query, prompt: Text("Cerca per nome o città"))
                } else {
                    List(store.state.vehicles) { vehicle in
                        Button {
                            self.vehicle = vehicle
                        } label: {
                            Label(vehicle.nickname, systemImage: vehicle.kind.symbol).foregroundStyle(SbuTheme.ink)
                        }
                    }
                }
            }
            .navigationTitle(vehicle == nil ? "Scegli un veicolo" : "Scegli una ZTL")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Chiudi", systemImage: "xmark") { dismiss() }
                }
            }
        }
    }
}
