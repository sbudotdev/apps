import SwiftUI

extension View {
    /// Rows scrolled up stop under a solid band, not crisp behind the sheet's Chiudi and Modifica
    /// buttons, where they read as one line on top of the other.
    @ViewBuilder
    func solidTopEdge() -> some View {
        if #available(iOS 26, *) {
            scrollEdgeEffectStyle(.hard, for: .top)
        } else {
            self
        }
    }
}
