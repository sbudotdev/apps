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
                IconButton(title: "Chiudi", symbol: "xmark") { model.phase = .place(place) }
            }
            Label(model.store.hasVehicle ? model.store.vehicle.nickname : String(localized: "Nessun veicolo: evito ogni zona"),
                  systemImage: model.store.vehicle.kind.symbol)
                .font(SbuTheme.subheadline)
                .foregroundStyle(SbuTheme.ink)
            if let walk = plan.walkMetres {
                let distance = Measurement(value: walk, unit: UnitLength.meters).formatted(.measurement(width: .abbreviated, usage: .road))
                if let zone = plan.destinationZone {
                    RouteNotice(symbol: "figure.walk", title: "L'arrivo è dentro \(zone)", detail: "Ti lascio al bordo, a \(distance) a piedi.")
                } else {
                    RouteNotice(symbol: "figure.walk", title: "L'ultimo tratto è a piedi", detail: "La strada finisce a \(distance) dall'arrivo.")
                }
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
            if let gap = model.catalog.city(at: place.point)?.missingPerimeters {
                RouteNotice(symbol: "exclamationmark.triangle", title: "Il percorso non evita ciò che non conosco", detail: "\(String(localized: gap))")
            }
            Text("Fa fede la segnaletica. Questa app non sostituisce gli atti del Comune.")
                .font(SbuTheme.footnote)
                .foregroundStyle(SbuTheme.inkMuted)
            #if DEBUG
            if let time = model.planTime {
                Text(verbatim: time.formatted(.units(allowed: [.milliseconds], width: .narrow)))
                    .font(SbuTheme.footnote)
                    .foregroundStyle(SbuTheme.inkMuted)
            }
            #endif
            SbuButton("Avvia") { model.start(plan, to: place) }
                .accessibilityIdentifier("start")
        }
    }
}
