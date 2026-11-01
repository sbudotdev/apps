import MapKit
import SbuKit
import SwiftUI

/// Status, time, distance and arrival; the end of the drive.
struct GuidanceBottomView: View {
    let guidance: GuidanceModel
    let place: Place
    @Bindable var model: MapModel
    @State private var hasClosed = false

    private var statusText: LocalizedStringKey {
        switch guidance.status {
        case .starting: "Avvio la navigazione"
        case .following: "Sul percorso"
        case .rerouting: "Ricalcolo il percorso"
        case .weakSignal: "Segnale GPS debole. Percorso mantenuto."
        case .arrived: "Arrivato"
        }
    }

    private var arrival: Date { .now.addingTimeInterval(guidance.state.remainingSeconds) }

    var body: some View {
        Panel {
            if model.isCameraDetached {
                Button("Riprendi", systemImage: "location.fill") { model.followUser() }
                .mapPill()
                .buttonStyle(.plain)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(statusText)
                if guidance.plan.isPartlyUncovered {
                    Text("Parte del percorso è fuori copertura.")
                }
            }
            .font(SbuTheme.footnote)
            .foregroundStyle(SbuTheme.inkMuted)

            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Duration.seconds(guidance.state.remainingSeconds), format: .units(allowed: [.hours, .minutes], width: .abbreviated, maximumUnitCount: 2))
                        .font(SbuTheme.title2)
                        .foregroundStyle(SbuTheme.ink)
                    Text(Measurement(value: guidance.state.remainingMetres, unit: UnitLength.meters), format: .measurement(width: .abbreviated, usage: .road))
                        .font(SbuTheme.subheadline)
                        .foregroundStyle(SbuTheme.inkMuted)
                }
                Spacer()
                Text(arrival, format: .dateTime.hour().minute())
                    .font(SbuTheme.headline)
                    .foregroundStyle(SbuTheme.ink)
                    .accessibilityLabel(Text("Arrivo alle \(arrival.formatted(.dateTime.hour().minute()))"))
                Button("Termina", systemImage: "xmark") { model.close() }
                    .labelStyle(.iconOnly)
                    .frame(minWidth: 44, minHeight: 44)
                    .foregroundStyle(SbuTheme.ink)
            }
        }
        .task(id: ObjectIdentifier(guidance)) {
            await guidance.run(location: model.location)
        }
        .onChange(of: guidance.status) { _, status in
            if status == .arrived { hasClosed = true }
        }
        .sbuClosure($hasClosed, word: "Arrivato")
    }
}
