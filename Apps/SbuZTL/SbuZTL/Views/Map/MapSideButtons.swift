import SbuKit
import SwiftUI

/// What the map shows, under the top bar.
struct MapSideButtons: View {
    @Bindable var model: MapModel

    var body: some View {
        Menu {
            Toggle("Mostra le zone", isOn: $model.showsZones)
            Toggle("Mostra i parcheggi", isOn: Bindable(model.store).state.showsParking)
        } label: {
            Image(systemName: "square.3.layers.3d")
                .fontWeight(.medium)
                .mapPill()
        }
        .accessibilityLabel(Text("Livelli"))
    }
}
