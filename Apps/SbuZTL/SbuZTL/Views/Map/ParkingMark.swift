import SbuKit
import SwiftUI

/// A parking on the map, in ink.
struct ParkingMark: View {
    let name: String

    var body: some View {
        Image(systemName: "parkingsign.circle.fill")
            .fontWeight(.medium)
            .foregroundStyle(SbuTheme.ink)
            .background(SbuTheme.paper, in: .circle)
            .accessibilityLabel(name.isEmpty ? Text("Parcheggio") : Text(verbatim: name))
    }
}

#Preview("Light") {
    ParkingMark(name: "Parcheggio Stazione").padding()
}

#Preview("Dark") {
    ParkingMark(name: "").padding().preferredColorScheme(.dark)
}
