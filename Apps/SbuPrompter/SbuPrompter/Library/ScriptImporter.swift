import AppKit
import PDFKit
import UniformTypeIdentifiers

/// Reads text, Markdown, RTF, Word, HTML and PDF files into a script title and body.
enum ScriptImporter {
    static let types: [UTType] = [
        .plainText, .rtf, .rtfd, .html, .pdf,
        UTType(filenameExtension: "md") ?? .plainText,
        UTType(filenameExtension: "docx") ?? .data,
        UTType(filenameExtension: "doc") ?? .data,
        UTType(filenameExtension: "odt") ?? .data,
    ]

    /// Extensions shown in the import help and the error message.
    static let extensionsList = ".txt, .md, .rtf, .docx, .doc, .odt, .html, .pdf"

    enum Failure: Error { case unreadable }

    /// Runs on the main actor: AppKit reads HTML through WebKit.
    static func read(_ url: URL) throws -> (title: String, body: String) {
        let title = url.deletingPathExtension().lastPathComponent
        let body: String
        switch url.pathExtension.lowercased() {
        case "pdf":
            guard let text = PDFDocument(url: url)?.string else { throw Failure.unreadable }
            body = unwrapLines(text)
        case "rtf", "rtfd", "doc", "docx", "odt", "html", "htm", "webarchive":
            // AppKit picks the reader from the file itself.
            body = try NSAttributedString(url: url, options: [:], documentAttributes: nil).string
        default:
            var encoding = String.Encoding.utf8
            // UTF-8 or a marked encoding first; old Windows and Mac files are often Latin-1.
            if let text = try? String(contentsOf: url, usedEncoding: &encoding) {
                body = text
            } else {
                body = try String(contentsOf: url, encoding: .isoLatin1)
            }
        }
        return (title, clean(body))
    }

    /// Windows line ends, line and paragraph separators, and attachment marks become plain lines.
    static func clean(_ text: String) -> String {
        text.replacing("\r\n", with: "\n")
            .replacing("\r", with: "\n")
            .replacing("\u{2028}", with: "\n")
            .replacing("\u{2029}", with: "\n")
            .replacing("\u{FFFC}", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// PDFs break every printed line: joins the lines of a paragraph, keeps blank lines between paragraphs.
    static func unwrapLines(_ text: String) -> String {
        clean(text)
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .split(separator: "", omittingEmptySubsequences: true)
            .map { $0.joined(separator: " ") }
            .joined(separator: "\n\n")
    }

    /// The first non-empty line, without heading marks: the title of a pasted script.
    static func title(fromText text: String) -> String? {
        let line = text.split(separator: "\n").lazy
            .map { $0.trimmingCharacters(in: .whitespaces).drop { $0 == "#" }.trimmingCharacters(in: .whitespaces) }
            .first { !$0.isEmpty }
        return line.map { String($0.prefix(60)) }
    }
}
