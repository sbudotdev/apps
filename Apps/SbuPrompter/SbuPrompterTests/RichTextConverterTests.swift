import AppKit
import Testing
@testable import SbuPrompter

struct RichTextConverterTests {
    private let body = NSFont.systemFont(ofSize: 12)
    private let bold = NSFont.boldSystemFont(ofSize: 12)
    private let italic = NSFontManager.shared.convert(NSFont.systemFont(ofSize: 12), toHaveTrait: .italicFontMask)

    private func run(_ text: String, _ font: NSFont) -> NSAttributedString {
        NSAttributedString(string: text, attributes: [.font: font])
    }

    private func document(_ runs: NSAttributedString...) -> NSAttributedString {
        let result = NSMutableAttributedString()
        runs.forEach(result.append)
        return result
    }

    @Test func largerShortParagraphBecomesASection() {
        let doc = document(run("Apertura\n", .systemFont(ofSize: 20)), run("Buongiorno a tutti, oggi parliamo di prompter.", body))
        #expect(RichTextConverter.script(from: doc) == "# Apertura\nBuongiorno a tutti, oggi parliamo di prompter.")
    }

    @Test func boldParagraphInAPlainDocumentBecomesASection() {
        let doc = document(run("Seconda parte\n", bold), run("Testo normale.", body))
        #expect(RichTextConverter.script(from: doc) == "# Seconda parte\nTesto normale.")
    }

    @Test func boldAndItalicWordsGetMarks() {
        let doc = document(run("Questo è ", body), run("molto importante ", bold), run("e ", body), run("delicato", italic), run(".", body))
        let script = RichTextConverter.script(from: doc)
        #expect(script == "Questo è **molto importante** e *delicato*.")
        #expect(ScriptMarkup.plainText(script) == "Questo è molto importante e delicato.")
    }

    @Test func runsSplitByColourMergeIntoOneMark() {
        let red = NSAttributedString(string: "parole ", attributes: [.font: bold, .foregroundColor: NSColor.red])
        let doc = document(run("Due ", body), run("belle ", bold), red, run("qui.", body))
        #expect(RichTextConverter.script(from: doc) == "Due **belle parole** qui.")
    }

    @Test func allBoldDocumentKeepsNoMarks() {
        let doc = document(run("Tutto in grassetto, una frase lunga che non è un titolo perché supera di parecchio la lunghezza di un titolo.", bold))
        #expect(!RichTextConverter.script(from: doc).contains("*"))
    }
}
