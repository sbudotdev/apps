import SwiftUI

/// The panel hanging from the notch: as wide as the notch in the menu bar row, so the menu bar
/// stays visible and clickable on both sides, then the full width below it, with rounded corners.
nonisolated struct NotchPanelShape: Shape {
    let notchHeight: CGFloat
    let notchWidth: CGFloat
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        let column = CGRect(x: rect.midX - notchWidth / 2, y: rect.minY, width: notchWidth, height: notchHeight)
        let body = CGRect(x: rect.minX, y: rect.minY + notchHeight, width: rect.width, height: max(rect.height - notchHeight, 0))
        var path = Path(column)
        path.addPath(UnevenRoundedRectangle(cornerRadii: .init(topLeading: cornerRadius, bottomLeading: cornerRadius,
                                                                 bottomTrailing: cornerRadius, topTrailing: cornerRadius))
            .path(in: body))
        return path
    }
}
