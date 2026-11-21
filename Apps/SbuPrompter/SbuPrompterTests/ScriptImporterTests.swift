import AppKit
import Foundation
import Testing
@testable import SbuPrompter

struct ScriptImporterTests {
    private func temporaryFile(_ name: String, _ data: Data) throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let url = folder.appending(path: name)
        try data.write(to: url)
        return url
    }

    @Test(arguments: ["copione.txt", "copione.md"])
    func readsPlainText(name: String) throws {
        let url = try temporaryFile(name, Data("# Titolo\nCiao a tutti.".utf8))
        let imported = try ScriptImporter.read(url)
        #expect(imported.title == "copione")
        #expect(imported.body == "# Titolo\nCiao a tutti.")
    }

    @Test func readsRichTextAsPlainText() throws {
        let rich = NSAttributedString(string: "Grassetto e corsivo.", attributes: [.font: NSFont.boldSystemFont(ofSize: 14)])
        let data = try rich.data(from: NSRange(location: 0, length: rich.length),
                                 documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
        let url = try temporaryFile("discorso.rtf", data)
        let imported = try ScriptImporter.read(url)
        #expect(imported.title == "discorso")
        #expect(imported.body == "Grassetto e corsivo.")
    }

    @Test func titleFromPastedTextIsItsFirstLine() {
        #expect(ScriptImporter.title(fromText: "\n  # Apertura del video\nTesto") == "Apertura del video")
        #expect(ScriptImporter.title(fromText: "   ") == nil)
    }
}
