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

    @Test(arguments: [NSAttributedString.DocumentType.officeOpenXML, .html, .openDocument])
    func readsWordHTMLAndOpenDocument(type: NSAttributedString.DocumentType) throws {
        let rich = NSAttributedString(string: "Buongiorno a tutti.\nSeconda riga.")
        let data = try rich.data(from: NSRange(location: 0, length: rich.length), documentAttributes: [.documentType: type])
        let ext = [NSAttributedString.DocumentType.officeOpenXML: "docx", .html: "html", .openDocument: "odt"][type] ?? "txt"
        let imported = try ScriptImporter.read(try temporaryFile("intervento.\(ext)", data))
        #expect(imported.title == "intervento")
        #expect(imported.body == "Buongiorno a tutti.\nSeconda riga.")
    }

    @Test func htmlHeadingsAndBoldBecomeScriptMarks() throws {
        let html = "<html><body><h1>Apertura</h1><p>Benvenuti, oggi parliamo di <b>teleprompter</b>.</p></body></html>"
        let imported = try ScriptImporter.read(try temporaryFile("talk.html", Data(html.utf8)))
        #expect(imported.body == "# Apertura\nBenvenuti, oggi parliamo di **teleprompter**.")
    }

    @Test func readsLatin1Text() throws {
        let url = try temporaryFile("vecchio.txt", try #require("Perché sì".data(using: .isoLatin1)))
        #expect(try ScriptImporter.read(url).body == "Perché sì")
    }

    @Test func cleanTurnsWindowsLineEndsIntoLines() {
        #expect(ScriptImporter.clean("Uno\r\nDue\rTre\u{2029}\u{FFFC}Quattro\n") == "Uno\nDue\nTre\nQuattro")
    }

    @Test func unwrapJoinsPrintedLinesAndKeepsParagraphs() {
        let pdf = "Questo è un paragrafo\nche va a capo\nnel PDF.\n\n  \nSecondo paragrafo.\n"
        #expect(ScriptImporter.unwrapLines(pdf) == "Questo è un paragrafo che va a capo nel PDF.\n\nSecondo paragrafo.")
    }

    @Test func titleFromPastedTextIsItsFirstLine() {
        #expect(ScriptImporter.title(fromText: "\n  # Apertura del video\nTesto") == "Apertura del video")
        #expect(ScriptImporter.title(fromText: "   ") == nil)
    }
}
