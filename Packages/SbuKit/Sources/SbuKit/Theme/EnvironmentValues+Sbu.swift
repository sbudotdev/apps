import SwiftUI

public extension EnvironmentValues {
    /// The accent of the app on screen, set by `SbuAppShell` and `SbuTabShell`: the `.set` full
    /// stop takes `base`, the Closure takes `onInk`. `nil` falls back to the tint.
    @Entry var sbuAccent: SbuAccent?

    /// Whether Sbu haptics play: `false` when the person turned the app's vibration off.
    /// The full stop's `dot`, the `tick` of `.sbuAffectsFigure` and the Closure follow it.
    @Entry var sbuPlaysHaptics = true

    /// The season on screen, `nil` outside every season. Defaults to today's date on the device;
    /// force it with `.environment(\.sbuSeason, .christmas)` in previews and tests.
    // shortcut: read once per view update, so an app left open across midnight on 30 Nov / 6 Jan
    // changes season at its next redraw; add a midnight timer if a season must flip live.
    @Entry var sbuSeason: SbuSeason? = SbuSeason.active(on: .now)
}

extension EnvironmentValues {
    /// Counts the times a control changed the figure, so the full stop can beat. Set by the shells.
    @Entry var sbuFigurePulse: SbuFigurePulse?

    /// Whether the view sits on `.sbuPaper`, whose coordinate space the hero figure snaps to.
    @Entry var sbuIsOnPaper = false
}
