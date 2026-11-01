import SbuKit
import SwiftUI

/// Time, distance and everything the route can't promise, before you start.
struct RoutePreviewPanel: View {
    @Bindable var model: MapModel
    let place: Place
    let plan: RoutePlan

    var body: some View {
        Panel {
            HStack(alignment: .firstTextBaseline, spacing: SbuTheme.space2) {
                Text(Duration.seconds(plan.seconds), format: .units(allowed: [.hours, .minutes], width: .abbreviated, maximumUnitCount: 2))
                    .font(SbuTheme.title2)
                    .foregroundStyle(SbuTheme.ink)
                Text(Measurement(value: plan.metres, unit: UnitLength.meters), format: .measurement(width: .abbreviated, usage: .road))
                    .font(SbuTheme.subheadline)
                    .foregroundStyle(SbuTheme.inkMuted)
                SbuFullStop(.set, size: .mark)
                Spacer()
                Button("Chiudi", systemImage: "xmark") { model.phase = .place(place) }
                    .labelStyle(.iconOnly)
                    .frame(minWidth: 44, minHeight: 44)
                    .foregroundStyle(SbuTheme.ink)
            }
            Label(model.store.hasVehicle ? model.store.vehicle.nickname : String(localized: "Nessun veicolo: evito ogni zona"),
                  systemImage: model.store.vehicle.kind.symbol)
                .font(SbuTheme.subheadline)
                .foregroundStyle(SbuTheme.ink)
            if let walk = plan.walkMetres, let zone = plan.destinationZone {
                RouteNotice(symbol: "figure.walk",
                            title: "L'arrivo è dentro \(zone)",
                            detail: "Ti lascio al bordo, a \(Measurement(value: walk, unit: UnitLength.meters).formatted(.measurement(width: .abbreviated, usage: .road))) a piedi.")
            }
            if let zone = plan.startZone {
                RouteNotice(symbol: "arrow.up.forward.circle",
                            title: "Parti dentro \(zone)",
                            detail: "Ti porto fuori dalla via più breve. Questo tratto non lo posso evitare.")
            }
            if plan.isPartlyUncovered {
                RouteNotice(symbol: "exclamationmark.triangle",
                            title: "Parte del percorso è fuori copertura",
                            detail: "In quei tratti non controllo le zone. Segui la segnaletica.")
            }
            Text("Fa fede la segnaletica. Questa app non sostituisce gli atti del Comune.")
                .font(SbuTheme.footnote)
                .foregroundStyle(SbuTheme.inkMuted)
            SbuButton("Avvia") { model.start(plan, to: place) }
                .accessibilityIdentifier("start")
        }
    }
}
