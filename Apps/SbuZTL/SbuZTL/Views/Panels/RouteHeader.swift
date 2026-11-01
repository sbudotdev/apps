import SbuKit
import SwiftUI

/// From where to where, above the route preview.
struct RouteHeader: View {
    let place: Place

    var body: some View {
        VStack(alignment: .leading, spacing: SbuTheme.space2) {
            Label("La tua posizione", systemImage: "location.fill")
            Label(place.name, systemImage: "mappin")
        }
        .font(SbuTheme.subheadline)
        .foregroundStyle(SbuTheme.ink)
        .padding(SbuTheme.space3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SbuTheme.surfaceRaised, in: RoundedRectangle(cornerRadius: SbuTheme.radiusCard))
        .overlay(RoundedRectangle(cornerRadius: SbuTheme.radiusCard).strokeBorder(SbuTheme.line))
        .padding(.horizontal, SbuTheme.space4)
    }
}

#Preview("Light") {
    RouteHeader(place: Place(name: "Porta Venezia", address: "", point: Point(45.47, 9.2)))
}

#Preview("Dark") {
    RouteHeader(place: Place(name: "Porta Venezia", address: "", point: Point(45.47, 9.2))).preferredColorScheme(.dark)
}
