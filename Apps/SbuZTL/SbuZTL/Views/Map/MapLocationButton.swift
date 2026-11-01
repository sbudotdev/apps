import SbuKit
import SwiftUI

/// Back to where you are, at the bottom right of the map. The first tap asks for the permission.
struct MapLocationButton: View {
    let model: MapModel

    var body: some View {
        IconButton(title: "La tua posizione", symbol: "location", isPill: true) {
            model.location.start()
            model.followUser()
        }
    }
}
