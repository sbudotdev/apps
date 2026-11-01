import SbuKit
import SwiftUI

/// Search, favorites, the zone list and the recent places.
struct HomePanel: View {
    @Bindable var model: MapModel

    var body: some View {
        Panel {
            Button {
                model.phase = .search
            } label: {
                Label("Cerca un luogo", systemImage: "magnifyingglass")
                    .font(SbuTheme.body)
                    .foregroundStyle(SbuTheme.inkMuted)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .padding(.horizontal, SbuTheme.space3)
                    .background(SbuTheme.paper, in: RoundedRectangle(cornerRadius: SbuTheme.radiusCard))
                    .overlay(RoundedRectangle(cornerRadius: SbuTheme.radiusCard).strokeBorder(SbuTheme.line))
            }
            .buttonStyle(.plain)
            .tourAnchor(.search)

            HStack(spacing: SbuTheme.space2) {
                NavigationLink {
                    FavoritesView(model: model)
                } label: {
                    HomeTile(title: "Preferiti", symbol: "bookmark")
                }
                NavigationLink {
                    ZoneListView(model: model)
                } label: {
                    HomeTile(title: "ZTL", symbol: "map")
                }
            }
            .buttonStyle(.plain)

            if let recent = model.store.state.recents.first {
                Button {
                    model.select(recent)
                } label: {
                    PlaceRow(place: recent, symbol: "arrow.counterclockwise")
                }
                .buttonStyle(.plain)
            }
        }
    }
}
