import AppKit

/// Turns a Word, RTF, OpenDocument or HTML document into script text: a short paragraph set larger
/// than the body (or all bold, in a document that isn't) becomes a `#` section, bold and italic
/// words get `**` and `*`, so what you stressed in Word is stressed in the prompter too.
enum RichTextConverter {
    /// Points above the body size from which a short paragraph counts as a heading.
    static let headingStep: CGFloat = 2
    static let headingMaxLength = 80

    static func script(from document: NSAttributedString) -> String {
        let text = document.string as NSString
        let bodySize = mostCommonFontSize(in: document)
        let hasPlainText = containsPlainText(document)
        var paragraphs: [String] = []
        text.enumerateSubstrings(in: NSRange(location: 0, length: text.length), options: .byParagraphs) { _, range, _, _ in
            paragraphs.append(paragraph(document, range: range, bodySize: bodySize, styled: hasPlainText))
        }
        return paragraphs.joined(separator: "\n")
    }

    private static func paragraph(_ document: NSAttributedString, range: NSRange, bodySize: CGFloat, styled: Bool) -> String {
        let plain = (document.string as NSString).substring(with: range).trimmingCharacters(in: .whitespaces)
        guard !plain.isEmpty else { return "" }
        var largest: CGFloat = 0
        var allBold = true
        document.enumerateAttribute(.font, in: range) { value, run, _ in
            guard let font = value as? NSFont else { allBold = false; return }
            let isBlank = (document.string as NSString).substring(with: run).allSatisfy(\.isWhitespace)
            if isBlank { return }
            largest = max(largest, font.pointSize)
            if !font.fontDescriptor.symbolicTraits.contains(.bold) { allBold = false }
        }
        let isShort = plain.count <= headingMaxLength
        if isShort, largest >= bodySize + headingStep || (styled && allBold) {
            return "# " + plain
        }
        guard styled else { return plain }

        // Runs split by anything but bold and italic (a colour, a size) merge, so marks never touch.
        var pieces: [(text: String, mark: String)] = []
        document.enumerateAttribute(.font, in: range) { value, run, _ in
            let text = (document.string as NSString).substring(with: run)
            let traits = (value as? NSFont)?.fontDescriptor.symbolicTraits ?? []
            var mark = ""
            if traits.contains(.bold) { mark += "**" }
            if traits.contains(.italic) { mark += "*" }
            if let last = pieces.last, last.mark == mark || text.allSatisfy(\.isWhitespace) {
                pieces[pieces.count - 1].text += text
            } else {
                pieces.append((text, mark))
            }
        }
        return pieces.map { wrap($0.text, in: $0.mark) }.joined().trimmingCharacters(in: .whitespaces)
    }

    /// Marks hug the words: "  bold " becomes "  **bold** ".
    static func wrap(_ piece: String, in mark: String) -> String {
        let core = piece.trimmingCharacters(in: .whitespaces)
        guard !mark.isEmpty, !core.isEmpty else { return piece }
        let leading = piece.prefix { $0.isWhitespace }
        let trailing = String(piece.reversed().prefix { $0.isWhitespace })
        return leading + mark + core + String(mark.reversed()) + trailing
    }

    private static func mostCommonFontSize(in document: NSAttributedString) -> CGFloat {
        var counts: [CGFloat: Int] = [:]
        document.enumerateAttribute(.font, in: NSRange(location: 0, length: document.length)) { value, run, _ in
            if let font = value as? NSFont { counts[font.pointSize, default: 0] += run.length }
        }
        return counts.max { $0.value < $1.value }?.key ?? 0
    }

    /// A document written all in bold has no emphasis to keep.
    private static func containsPlainText(_ document: NSAttributedString) -> Bool {
        var found = false
        document.enumerateAttribute(.font, in: NSRange(location: 0, length: document.length)) { value, run, stop in
            let text = (document.string as NSString).substring(with: run)
            guard !text.allSatisfy(\.isWhitespace) else { return }
            let traits = (value as? NSFont)?.fontDescriptor.symbolicTraits ?? []
            if !traits.contains(.bold) { found = true; stop.pointee = true }
        }
        return found
    }
}
