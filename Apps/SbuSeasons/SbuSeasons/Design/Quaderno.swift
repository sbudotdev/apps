import AppKit
import CoreText
import SwiftUI

/// I token del Quaderno (ADR-0013) che servono a Sbu Seasons, copiati da `Design/tokens.json`.
///
/// shortcut: copia a mano perché SbuKit non supporta ancora macOS; `QuadernoTokensTests` la confronta
/// con `tokens.json`. Quando SbuKit avrà macOS, si usa `SbuTheme` e questo file sparisce.
nonisolated enum Quaderno {
    // MARK: Colori

    static let paper = Tinta(token: "paper", light: 0xf6f6f2, dark: 0x0c0c0a)
    static let ink = Tinta(token: "ink", light: 0x0a0a00, dark: 0xf6f6f2)
    static let inkMuted = Tinta(token: "ink-muted", light: 0x6b6b63, dark: 0x9a9a92)

    static let colors = [paper, ink, inkMuted]

    // MARK: Misure

    static let space1: CGFloat = 4
    static let space4: CGFloat = 16
    static let space6: CGFloat = 24
    static let titleSize: CGFloat = 34
    static let titleWidth: CGFloat = 87
    static let cartiglioSize: CGFloat = 11
    static let cartiglioTracking: CGFloat = 0.1
    /// Lato della cella del reticolo: le misure della finestra Impostazioni ne sono multipli.
    static let gridCell: CGFloat = 24

    /// Le misure sopra, con il nome del token, per il test.
    static let metrics: [String: CGFloat] = [
        "space-1": space1,
        "space-4": space4,
        "space-6": space6,
        "title-size": titleSize,
        "figure-width-mid": titleWidth,
        "cartiglio-size": cartiglioSize,
        "cartiglio-tracking": cartiglioTracking,
        "grid-cell": gridCell,
    ]

    // MARK: Caratteri

    /// Bricolage Grotesque e IBM Plex Mono, nel bundle dell'app da `Design/fonts` (OFL).
    /// Leggerlo li registra la prima volta.
    static let fontsAreRegistered: Bool = ["BricolageGrotesque-Variable", "IBMPlexMono-Medium"].allSatisfy { name in
        guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else { return false }
        var error: Unmanaged<CFError>?
        if CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) { return true }
        return error.map { CFErrorGetCode($0.takeRetainedValue()) } == CTFontManagerError.alreadyRegistered.rawValue
    }

    /// Titolo: Bricolage ExtraBold 34, larghezza 87, come `SbuScreenTitle`.
    static var titleFont: Font {
        _ = fontsAreRegistered
        let variation: [Int: CGFloat] = [
            0x7767_6874: 800,          // wght
            0x7764_7468: titleWidth,   // wdth
            0x6F70_737A: titleSize,    // opsz
        ]
        let attributes: [CFString: Any] = [
            kCTFontNameAttribute: "BricolageGrotesque-96ptExtraBold",
            kCTFontVariationAttribute: variation,
        ]
        let descriptor = CTFontDescriptorCreateWithAttributes(attributes as CFDictionary)
        return Font(CTFontCreateWithFontDescriptor(descriptor, titleSize, nil))
    }

    /// Cartiglio: IBM Plex Mono Medium 11.
    static var cartiglioFont: Font {
        _ = fontsAreRegistered
        return .custom("IBMPlexMono-Medium", fixedSize: cartiglioSize)
    }
}
