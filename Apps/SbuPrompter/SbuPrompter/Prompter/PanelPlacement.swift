import CoreGraphics

/// Where the prompter panel goes on a screen: hanging from the notch, or as a pill
/// under the menu bar on screens without one. Pure geometry, so it is tested without a notch.
nonisolated struct PanelPlacement: Equatable {
    enum Style: Equatable { case notch, pill }

    /// What the placement needs from `NSScreen`.
    struct Screen: Equatable {
        var frame: CGRect
        var visibleFrame: CGRect
        /// `safeAreaInsets.top`: the notch height, 0 without a notch.
        var safeAreaTop: CGFloat
        /// `auxiliaryTopLeftArea` / `auxiliaryTopRightArea` widths, the menu bar on each side of the notch.
        var leftAuxiliaryWidth: CGFloat?
        var rightAuxiliaryWidth: CGFloat?
    }

    static let pillGap: CGFloat = 8

    let style: Style
    let frame: CGRect
    let notchHeight: CGFloat
    let notchWidth: CGFloat

    init(screen: Screen, width: CGFloat, height: CGFloat, forcePill: Bool) {
        let hasNotch = screen.safeAreaTop > 0 && !forcePill
        if hasNotch {
            let notchWidth = screen.frame.width - (screen.leftAuxiliaryWidth ?? 0) - (screen.rightAuxiliaryWidth ?? 0)
            let width = min(max(width, notchWidth), screen.frame.width)
            let height = min(max(height, screen.safeAreaTop), screen.frame.height)
            style = .notch
            notchHeight = screen.safeAreaTop
            self.notchWidth = notchWidth
            frame = CGRect(x: screen.frame.midX - width / 2, y: screen.frame.maxY - height, width: width, height: height)
        } else {
            let width = min(width, screen.frame.width)
            let height = min(height, screen.visibleFrame.height - Self.pillGap)
            style = .pill
            notchHeight = 0
            notchWidth = 0
            frame = CGRect(x: screen.frame.midX - width / 2, y: screen.visibleFrame.maxY - height - Self.pillGap,
                           width: width, height: height)
        }
    }
}
