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

    private var forbiddenNow: Int {
        model.catalog.zones.count {
            RuleEngine.verdict(zone: $0, vehicle: model.store.vehicle, at: model.moment, permits: model.store.state.permits).access == .forbidden
        }
    }

    private var cartiglio: String {
        (["Sbu", "ZTL", model.moment.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))]).joined(separator: " · ")
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: SbuTheme.space4) {
                    SbuScreenTitle("ZTL", cartiglio: cartiglio)
                    SbuFigure(value: forbiddenNow.formatted(), fullStop: model.store.hasVehicle ? .set : .waiting,
                              context: model.store.hasVehicle ? Text("zone vietate adesso a \(model.store.vehicle.nickname)") : Text("zone vietate adesso"))
                }
                // Clear of the grouped row's rounded corners, which clip what touches them.
                .padding(.vertical, SbuTheme.space6)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
            ForEach(City.allCases) { city in
                let zones = zones(in: city)
                if !zones.isEmpty {
                    Section(city.name) {
                        ForEach(zones) { zone in
                            NavigationLink {
                                ZoneDetailView(model: model, zone: zone)
                            } label: {
                                ZoneRow(zone: zone, verdict: RuleEngine.verdict(zone: zone, vehicle: model.store.vehicle, at: model.moment, permits: model.store.state.permits), showsChevron: false)
                            }
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(SbuTheme.paper)
        .searchable(text: $query, prompt: Text("Cerca per nome o città"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
