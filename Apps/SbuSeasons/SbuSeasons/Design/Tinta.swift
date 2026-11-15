import AppKit
import SwiftUI

/// Un colore del Quaderno, con il valore chiaro e scuro di `Design/tokens.json`.
nonisolated struct Tinta: Sendable {
    /// Il nome del token in `tokens.json`, per esempio `ink-muted`.
    let token: String
    let light: UInt32
    let dark: UInt32

    /// Segue l'aspetto chiaro o scuro della finestra.
    var nsColor: NSColor {
        let light = light, dark = dark
        return NSColor(name: NSColor.Name(token)) { appearance in
            Self.color(appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light)
        }
    }

    var color: Color { Color(nsColor: nsColor) }

    /// Il valore chiaro, fisso: per la neve, che è sempre bianco carta qualunque sia l'aspetto.
    var lightColor: NSColor { Self.color(light) }

    /// Il valore scuro, fisso.
    var darkColor: NSColor { Self.color(dark) }

    private static func color(_ hex: UInt32) -> NSColor {
        NSColor(
            srgbRed: CGFloat(hex >> 16 & 0xff) / 255,
            green: CGFloat(hex >> 8 & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255,
            alpha: 1
        )
    }
}
