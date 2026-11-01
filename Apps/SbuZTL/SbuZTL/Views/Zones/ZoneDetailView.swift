import SbuKit
import SwiftUI

/// A zone's rules, with where they come from.
struct ZoneDetailView: View {
    @Bindable var model: MapModel
    let zone: Zone

    private var verdict: Verdict {
        RuleEngine.verdict(zone: zone, vehicle: model.store.vehicle, at: model.moment, permits: model.store.state.permits)
    }

    var body: some View {
        List {
            Section {
                AnswerCard(headline: verdict.access.headline, detail: verdict.reason, tint: verdict.access.tint, symbol: verdict.access.symbol, isCertain: verdict.access != .unknown)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
            if case .paid(let euros) = verdict.access {
                Section("Ticket") {
                    Text(euros, format: .currency(code: "EUR"))
                }
            }
            Section {
                NavigationLink("Calendario del veicolo") {
                    VehicleCalendarView(zone: zone, vehicle: model.store.vehicle, permits: model.store.state.permits)
                }
            }
            if let section = zone.section {
                Section("Tratto") { Text(section) }
            }
            if let exceptions = zone.exceptions {
                Section("Deroghe") { Text(exceptions) }
            }
            Section {
                if let act = zone.act { LabeledContent("Atto", value: act) }
                if let source = verdict.source {
                    if let url = source.url {
                        Link(source.title, destination: url)
                    } else {
                        Text(source.title)
                    }
                    LabeledContent("Verificata il", value: source.verified)
                }
            } header: {
                Text("Fonte")
            } footer: {
                Text("Fa fede la segnaletica. Questa app non sostituisce gli atti del Comune.")
            }
            if let url = ReportMail.url(zone: zone.name) {
                Section {
                    Link("Segnala un dato sbagliato", destination: url)
                }
            }
        }
        .navigationTitle(zone.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
