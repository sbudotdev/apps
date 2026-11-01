import SbuKit
import SwiftUI

/// Vehicles, permits, map and route preferences.
struct RouteSettingsSection: View {
    @Bindable var store: AppStore
    let catalog: ZoneCatalog
    let replayIntro: () -> Void

    var body: some View {
        Section("Veicoli e accessi") {
            NavigationLink("I tuoi veicoli") { VehiclesView(store: store) }
            NavigationLink("Permessi") { PermitsView(store: store, catalog: catalog) }
        }
        Section {
            Toggle("Evita le zone a pagamento", isOn: $store.state.avoidsPaidZones)
        } header: {
            Text("Percorso")
        } footer: {
            Text("Se lo spegni, il percorso può attraversare Area C: il ticket lo paghi tu sul sito del Comune.")
        }
        Section("Mappa") {
            Toggle("Mantieni il nord in alto", isOn: $store.state.keepsNorthUp)
            Toggle("Edifici 3D", isOn: $store.state.shows3D)
            Toggle("Mostra i parcheggi", isOn: $store.state.showsParking)
        }
        Section("Aiuto") {
            Button("Rivedi l'introduzione", action: replayIntro)
            NavigationLink("Fonti dei dati") { DataSourcesView() }
            if let url = URL(string: "https://github.com/sbudotdev/apps/issues/new") {
                Link("Segnala un dato sbagliato", destination: url)
            }
        }
        #if DEBUG
        Section("Prova su strada") {
            ForEach(TraceRecorder.files, id: \.self) { file in
                ShareLink(item: file) { Text(file.lastPathComponent) }
            }
        }
        #endif
    }
}
