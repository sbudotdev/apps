import AppKit

/// Disegna il filo delle Luci in alto (SBU-229). Si ridisegna solo quando cambia qualcosa: con Fisse, una volta.
final class TopLightsView: NSView {
    var palette = TopLights.Palette.multicolor { didSet { redraw(palette != oldValue) } }
    var single = TopLights.SingleColor.red { didSet { redraw(single != oldValue) } }
    var shape = TopLights.Shape.round { didSet { redraw(shape != oldValue) } }
    var animation = TopLights.Animation.steady { didSet { redraw(animation != oldValue) } }
    /// Secondi dall'accensione: muovono l'animazione.
    var time: Double = 0 { didSet { redraw(animation.moves) } }

    override var isFlipped: Bool { false }

    private func redraw(_ changed: Bool) {
        if changed { needsDisplay = true }
    }

    override func draw(_ dirtyRect: NSRect) {
        TopLightsArt.draw(in: bounds, colors: TopLightsArt.colors(palette, single: single), shape: shape,
                          animation: animation, time: time)
    }
}
