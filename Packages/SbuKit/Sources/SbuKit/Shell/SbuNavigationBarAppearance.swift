// iOS only: the shell has no place on Apple Watch.
#if os(iOS)

import UIKit

/// The navigation bar of every Sbu screen.
///
/// A band of `paper`, at the top of a screen too: every screen is on paper, so at rest it looks
/// the same as a clear bar, and once the content scrolls nothing passes under the clock, and the
/// figure is never seen cut by the status bar. Always opaque, because a screen with a bottom
/// action does not tell the bar it scrolled, and a clear bar then turned black over the figure. Large navigation titles of management screens
/// are in the title face, Bricolage ExtraBold width 87, scaled with Dynamic Type like
/// `.largeTitle`; inline titles stay SF.
enum SbuNavigationBarAppearance {
    /// Applies the appearance once per process; the shells call it before their first bar exists.
    static let apply: Void = {
        let font = SbuFont.figure(size: SbuTheme.titleSize, width: SbuTheme.figureWidthMid) as UIFont
        let largeTitle: [NSAttributedString.Key: Any] = [
            .font: UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: font),
        ]

        let paper = UINavigationBarAppearance()
        paper.configureWithOpaqueBackground()
        paper.backgroundColor = UIColor(named: "paper", in: .module, compatibleWith: nil)
        paper.shadowColor = .clear
        paper.largeTitleTextAttributes = largeTitle

        let bar = UINavigationBar.appearance()
        bar.standardAppearance = paper
        bar.compactAppearance = paper
        bar.scrollEdgeAppearance = paper
        bar.compactScrollEdgeAppearance = paper
    }()
}

#endif
