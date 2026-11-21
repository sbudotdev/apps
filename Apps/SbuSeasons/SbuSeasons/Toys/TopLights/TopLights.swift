import CoreGraphics

/// «Luci in alto» (SBU-229): un filo di luci appena sotto la barra dei menu, da un orlo all'altro dello schermo.
/// Qui solo i conti, provati senza disegnare: dove pende il filo, dove stanno le lampadine, quanto è accesa ognuna.
/// Il disegno è in `TopLightsArt`, la finestra in `TopLightsPanel`, chi le accende in `TopLightsStrip`.
nonisolated enum TopLights {
    /// I colori delle lampadine: misti, caldi, freddi, o tutti di `SingleColor`.
    enum Palette: String, Codable, CaseIterable, Sendable { case multicolor, warm, cold, single }
    enum SingleColor: String, Codable, CaseIterable, Sendable { case red, gold, white, blue, green }
    enum Shape: String, Codable, CaseIterable, Sendable { case round, drop, star }
    enum Animation: String, Codable, CaseIterable, Sendable {
        case steady, chase, slowBlink, wave

        /// Fisse non hanno bisogno dell'orologio: si disegnano una volta.
        var moves: Bool { self != .steady }
    }

    /// Con Riduci movimento le luci restano fisse, qualunque animazione sia scelta.
    static func animation(_ chosen: Animation, reduceMotion: Bool) -> Animation { reduceMotion ? .steady : chosen }

    /// I ganci del filo, da 0 a `width` compresi: campate di circa `topLightsSpan` pt, tutte uguali.
    static func hookXs(width: CGFloat) -> [CGFloat] {
        let spans = max(1, Int((width / Tuning.topLightsSpan).rounded()))
        return (0...spans).map { width * CGFloat($0) / CGFloat(spans) }
    }

    /// Quanto pende il filo in `x` sotto i ganci: niente ai ganci, `topLightsSag` a metà campata.
    static func sag(at x: CGFloat, width: CGFloat) -> CGFloat {
        let span = width / CGFloat(max(1, Int((width / Tuning.topLightsSpan).rounded())))
        let t = (x / span) - (x / span).rounded(.down)
        return Tuning.topLightsSag * 4 * t * (1 - t)
    }

    /// Le lampadine a distanza regolare, almeno `topLightsBulbGap`, con mezzo passo di margine sui due orli.
    static func bulbXs(width: CGFloat) -> [CGFloat] {
        let count = max(1, Int(width / Tuning.topLightsBulbGap))
        return (0..<count).map { width * (CGFloat($0) + 0.5) / CGFloat(count) }
    }

    /// Quanto è accesa la lampadina `index` al tempo `time` (s): da `topLightsDim` a 1.
    static func glow(index: Int, time: Double, animation: Animation) -> CGFloat {
        let dim = Tuning.topLightsDim
        switch animation {
        case .steady:
            return 1
        case .chase:
            let turn = Int((time / Tuning.topLightsChaseStep).rounded(.down))
            return (index - turn) % Tuning.topLightsChaseGroup == 0 ? 1 : dim
        case .slowBlink:
            let wave = 0.5 + 0.5 * cos(2 * .pi * time / Tuning.topLightsBlinkPeriod)
            return dim + (1 - dim) * wave
        case .wave:
            let wave = 0.5 + 0.5 * sin(2 * .pi * (time / Tuning.topLightsWavePeriod - Double(index) / Tuning.topLightsWaveLength))
            return dim + (1 - dim) * wave
        }
    }
}
