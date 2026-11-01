import SbuKit
import SwiftUI

/// A place in a list.
struct PlaceRow: View {
    let place: Place
    var symbol: String?
    var distance: Double?

    var body: some View {
        HStack(spacing: SbuTheme.space3) {
            Image(systemName: symbol ?? place.symbol)
                .fontWeight(.medium)
                .foregroundStyle(SbuTheme.ink)
                .frame(width: SbuTheme.space6)
            VStack(alignment: .leading, spacing: 2) {
                Text(place.name)
                    .font(SbuTheme.body)
                    .foregroundStyle(SbuTheme.ink)
                if !place.address.isEmpty {
                    Text(place.address)
                        .font(SbuTheme.footnote)
                        .foregroundStyle(SbuTheme.inkMuted)
                }
            }
            Spacer(minLength: 0)
            if let distance {
                Text(Measurement(value: distance, unit: UnitLength.meters), format: .measurement(width: .abbreviated, usage: .road))
                    .font(SbuTheme.footnote)
                    .foregroundStyle(SbuTheme.inkMuted)
            }
        }
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

#Preview("Light") {
    PlaceRow(place: Place(name: "Duomo", address: "Milano", point: Point(45.46, 9.19)), distance: 1200).padding()
}

#Preview("Dark") {
    PlaceRow(place: Place(name: "Duomo", address: "Milano", point: Point(45.46, 9.19)), distance: 1200).padding().preferredColorScheme(.dark)
}
