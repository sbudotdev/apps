import SbuKit
import SwiftUI

/// The saved places.
struct FavoritesView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var model: MapModel

    var body: some View {
        Group {
            if model.store.state.favorites.isEmpty {
                ScrollView {
                    SbuEmpty(sentence: "Salva un luogo per ritrovarlo qui.")
                        .padding(SbuTheme.space4)
                }
                .sbuPaper(grid: true)
            } else {
                List {
                    ForEach(model.store.state.favorites) { place in
                        Button {
                            model.select(place)
                            dismiss()
                        } label: {
                            PlaceRow(place: place)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { model.store.state.favorites.remove(atOffsets: $0) }
                }
            }
        }
        .navigationTitle("Preferiti")
    }
}
