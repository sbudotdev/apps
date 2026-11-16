import AppKit

/// Sbu Seasons nasce da CozySnow di Simone Antoniciello: il credito sta nel pannello Informazioni e nelle Impostazioni.
nonisolated enum Credits {
    static let sentence = String(localized: "Nata da CozySnow di Simone Antoniciello")
    static let url = URL(string: "https://github.com/antonsimo")!
    static let linkTitle = "github.com/antonsimo"

    /// I credits del pannello "Informazioni su Sbu Seasons": la frase, poi il link, centrati.
    static var aboutPanel: NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let base: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: paragraph,
        ]
        let text = NSMutableAttributedString(string: sentence + "\n", attributes: base)
        var link = base
        link[.link] = url
        text.append(NSAttributedString(string: linkTitle, attributes: link))
        return text
    }
}
