import SbuKit
import SwiftUI

/// The look of the controls floating on the map.
struct MapPillModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(SbuTheme.subheadline.weight(.medium))
            .foregroundStyle(SbuTheme.ink)
            .padding(.horizontal, SbuTheme.space3)
            .frame(minHeight: 44)
            .background(SbuTheme.surfaceRaised, in: RoundedRectangle(cornerRadius: SbuTheme.radiusCard))
            .overlay(RoundedRectangle(cornerRadius: SbuTheme.radiusCard).strokeBorder(SbuTheme.line))
    }
}

extension View {
    func mapPill() -> some View { modifier(MapPillModifier()) }
}
