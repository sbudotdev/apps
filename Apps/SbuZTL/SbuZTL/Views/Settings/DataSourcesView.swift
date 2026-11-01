import SbuKit
import SwiftUI

/// Whose data this is, as the licences ask.
struct DataSourcesView: View {
    var body: some View {
        List {
            Section("Strade e parcheggi") {
                Text("Grafo stradale e parcheggi © OpenStreetMap contributors, Open Database License.")
                if let url = URL(string: "https://www.openstreetmap.org/copyright") {
                    Link("openstreetmap.org/copyright", destination: url)
                }
            }
            Section("Zone") {
                ForEach(City.allCases) { city in
                    if let url = city.source {
                        Link(city.name, destination: url)
                    }
                }
                Text("Perimetri dai dati aperti dei Comuni. Verificati il 1 novembre 2026.")
            }
            ForEach(City.allCases) { city in
                Section("Dati di \(city.name)") {
                    ForEach(Dataset.all(in: city)) { dataset in
                        Link(destination: dataset.url) {
                            LabeledContent {
                                Text(verbatim: dataset.licence)
                            } label: {
                                Text(verbatim: dataset.title)
                                Text(verbatim: dataset.entity)
                            }
                        }
                    }
                }
            }
            Section("Mappa e ricerca") {
                Text("Mappa, ricerca dei luoghi e percorso fuori dalle città coperte vengono da Apple Maps.")
            }
        }
        .navigationTitle("Fonti dei dati")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Light") {
    NavigationStack { DataSourcesView() }
}

#Preview("Dark") {
    NavigationStack { DataSourcesView() }.preferredColorScheme(.dark)
}
