import SbuKit
import SwiftUI

/// Back to where you are, at the bottom right of the map. The first tap asks for the permission.
struct MapLocationButton: View {
    let model: MapModel

    var body: some View {
        Button("La tua posizione", systemImage: "location") {
            model.location.start()
            model.followUser()
        }
        .labelStyle(.iconOnly)
        .fontWeight(.medium)
        .mapPill()
        .buttonStyle(.plain)
    }
}
