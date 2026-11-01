import SbuKit
import SwiftUI

/// The search, over the whole screen, with the keyboard up.
struct SearchScreen: View {
    @Bindable var model: MapModel
    @State private var search = SearchModel()
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: SbuTheme.space2) {
                IconButton(title: "Chiudi", symbol: "chevron.down") { model.phase = .home }
                TextField("Nome o indirizzo", text: $search.query)
                    .focused($isFocused)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(.horizontal, SbuTheme.space4)
            .padding(.vertical, SbuTheme.space2)

            List {
                if search.query.isEmpty {
                    if !model.store.state.recents.isEmpty {
                        Section("Recenti") {
                            ForEach(model.store.state.recents) { place in
                                row(place, symbol: "arrow.counterclockwise")
                            }
                            .onDelete { model.store.state.recents.remove(atOffsets: $0) }
                        }
                    } else {
                        Text("Cerca un luogo, una via o una città.")
                            .font(SbuTheme.body)
                            .foregroundStyle(SbuTheme.inkMuted)
                    }
                } else if search.isSearching && search.results.isEmpty {
                    ProgressView().frame(maxWidth: .infinity)
                } else if search.results.isEmpty {
                    Text("Nessun risultato.")
                        .font(SbuTheme.body)
                        .foregroundStyle(SbuTheme.inkMuted)
                } else {
                    ForEach(search.results) { row($0, symbol: nil) }
                }
            }
            .listStyle(.plain)
            .scrollDismissesKeyboard(.interactively)
        }
        .background(SbuTheme.paper)
        .onAppear { isFocused = true }
        .task(id: search.query) { await search.search(near: model.location.fix?.point) }
    }

    private func row(_ place: Place, symbol: String?) -> some View {
        Button {
            model.select(place)
        } label: {
            PlaceRow(place: place, symbol: symbol, distance: model.location.fix.map { $0.point.metres(to: place.point) })
        }
        .buttonStyle(.plain)
    }
}
