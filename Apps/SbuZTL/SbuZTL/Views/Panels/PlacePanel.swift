import MapKit
import SbuKit
import SwiftUI

/// A place: its answer for your vehicle and moment, its zones, and the way there.
struct PlacePanel: View {
    @Bindable var model: MapModel
    let place: Place

    private var verdicts: [(zone: Zone, verdict: Verdict)] { model.verdicts(at: place.point) }

    var body: some View {
        Panel {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(place.name)
                        .font(SbuTheme.title2)
                        .foregroundStyle(SbuTheme.ink)
                    if let fix = model.location.fix {
                        Text(Measurement(value: fix.point.metres(to: place.point), unit: UnitLength.meters), format: .measurement(width: .abbreviated, usage: .road))
                            .font(SbuTheme.footnote)
                            .foregroundStyle(SbuTheme.inkMuted)
                    }
                    if !place.address.isEmpty {
                        Text(place.address)
                            .font(SbuTheme.footnote)
                            .foregroundStyle(SbuTheme.inkMuted)
                    }
                }
                Spacer()
                Button("Chiudi", systemImage: "xmark") { model.close() }
                    .labelStyle(.iconOnly)
                    .frame(minWidth: 44, minHeight: 44)
                    .foregroundStyle(SbuTheme.ink)
            }
            actions
            ScrollView {
                VStack(alignment: .leading, spacing: SbuTheme.space3) {
                    answer
                    ForEach(verdicts, id: \.zone.id) { item in
                        NavigationLink {
                            ZoneDetailView(model: model, zone: item.zone)
                        } label: {
                            ZoneRow(zone: item.zone, verdict: item.verdict)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxHeight: 220)
            SbuButton("Calcola percorso") { model.plan(to: place) }
                .accessibilityIdentifier("go")
        }
    }

    private var actions: some View {
        HStack(spacing: SbuTheme.space2) {
            Button {
                model.store.toggleFavorite(place)
            } label: {
                PlaceAction(title: model.store.isFavorite(place) ? "Salvato" : "Salva",
                            symbol: model.store.isFavorite(place) ? "bookmark.fill" : "bookmark")
            }
            ShareLink(item: Self.mapsURL(place), subject: Text(place.name)) {
                PlaceAction(title: "Condividi", symbol: "square.and.arrow.up")
            }
            Link(destination: Self.mapsURL(place)) {
                PlaceAction(title: "Apri in Mappe", symbol: "map")
            }
        }
        .buttonStyle(.plain)
    }

    private static func mapsURL(_ place: Place) -> URL {
        var components = URLComponents(string: "https://maps.apple.com/")
        components?.queryItems = [URLQueryItem(name: "ll", value: "\(place.point.lat),\(place.point.lon)"), URLQueryItem(name: "q", value: place.name)]
        return components?.url ?? URL(filePath: "/")
    }

    /// The sentence the app exists for, with the one full stop on the screen.
    @ViewBuilder
    private var answer: some View {
        if model.catalog.city(at: place.point) == nil {
            AnswerCard(headline: "Zona non coperta", detail: "Qui non ho dati. Segui la segnaletica.", tint: SbuTheme.warning, symbol: "questionmark.circle", isCertain: false)
        } else if let worst = RuleEngine.worst(verdicts.map(\.verdict)) {
            AnswerCard(headline: worst.access.headline, detail: worst.reason, tint: worst.access.tint, symbol: worst.access.symbol, isCertain: worst.access != .unknown)
        } else {
            AnswerCard(headline: "Nessuna zona qui", detail: "Non risultano limiti in questo punto. Fa fede la segnaletica.", tint: SbuTheme.success, symbol: "checkmark.circle", isCertain: true)
        }
    }
}
