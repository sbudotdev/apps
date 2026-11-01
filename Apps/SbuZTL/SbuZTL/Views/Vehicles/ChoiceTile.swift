import SbuKit
import SwiftUI

/// One of the options in a step of the vehicle flow.
struct ChoiceTile: View {
    let title: String
    var symbol: String?
    let isSelected: Bool

    var body: some View {
        HStack(spacing: SbuTheme.space3) {
            if let symbol {
                Image(systemName: symbol).fontWeight(.medium)
            }
            Text(title).font(SbuTheme.body)
            Spacer(minLength: 0)
            SbuRowMark(filled: isSelected)
        }
        .foregroundStyle(SbuTheme.ink)
        .padding(SbuTheme.space3)
        .frame(minHeight: 52)
        .background(SbuTheme.surfaceRaised, in: RoundedRectangle(cornerRadius: SbuTheme.radiusCard))
        .overlay(RoundedRectangle(cornerRadius: SbuTheme.radiusCard).strokeBorder(isSelected ? SbuTheme.ink : SbuTheme.line))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

#Preview("Light") {
    ChoiceTile(title: "Auto", symbol: "car.fill", isSelected: true).padding()
}

#Preview("Dark") {
    ChoiceTile(title: "Moto", symbol: "motorcycle.fill", isSelected: false).padding().preferredColorScheme(.dark)
}
