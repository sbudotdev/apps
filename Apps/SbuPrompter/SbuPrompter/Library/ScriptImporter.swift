import AppKit
import UniformTypeIdentifiers

/// Reads `.txt`, `.md` and `.rtf` files into a script title and body.
nonisolated enum ScriptImporter {
    static let types: [UTType] = [.plainText, .rtf, UTType(filenameExtension: "md") ?? .plainText]

    static func read(_ url: URL) throws -> (title: String, body: String) {
        let title = url.deletingPathExtension().lastPathComponent
        if url.pathExtension.lowercased() == "rtf" {
            let text = try NSAttributedString(url: url, options: [.documentType: NSAttributedString.DocumentType.rtf],
                                              documentAttributes: nil)
            return (title, text.string)
        }
        return (title, try String(contentsOf: url, encoding: .utf8))
    }

    /// The first non-empty line, without heading marks: the title of a pasted script.
    static func title(fromText text: String) -> String? {
        let line = text.split(separator: "\n").lazy
            .map { $0.trimmingCharacters(in: .whitespaces).drop { $0 == "#" }.trimmingCharacters(in: .whitespaces) }
            .first { !$0.isEmpty }
        return line.map { String($0.prefix(60)) }
    }
}
