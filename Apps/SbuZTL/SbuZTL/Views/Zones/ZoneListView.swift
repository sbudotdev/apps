import SbuKit
import SwiftUI

/// Every covered zone by city, with its answer now.
struct ZoneListView: View {
    @Bindable var model: MapModel
    @State private var query = ""

    private func zones(in city: City) -> [Zone] {
        let all = model.catalog.zones(in: city).sorted { $0.name < $1.name }
        return query.isEmpty ? all : all.filter { $0.name.localizedStandardContains(query) || city.name.localizedStandardContains(query) }
    }

    var body: some View {
        List {
            ForEach(City.allCases) { city in
                let zones = zones(in: city)
                if !zones.isEmpty {
                    Section(city.name) {
                        ForEach(zones) { zone in
                            NavigationLink {
                                ZoneDetailView(model: model, zone: zone)
                            } label: {
                                ZoneRow(zone: zone, verdict: RuleEngine.verdict(zone: zone, vehicle: model.store.vehicle, at: model.moment, permits: model.store.state.permits))
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $query, prompt: Text("Cerca per nome o città"))
        .navigationTitle("ZTL")
    }
}
