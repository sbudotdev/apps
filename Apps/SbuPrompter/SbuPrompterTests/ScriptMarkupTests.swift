import Testing
@testable import SbuPrompter

struct ScriptMarkupTests {
    @Test func boldAndItalicLoseTheirMarks() {
        let tokens = ScriptMarkup.tokens(in: "Questo è **molto importante** e *delicato*.")
        #expect(tokens.map(\.text) == ["Questo", "è", "molto", "importante", "e", "delicato."])
        #expect(tokens.map(\.isBold) == [false, false, true, true, false, false])
        #expect(tokens.map(\.isItalic) == [false, false, false, false, false, true])
    }

    @Test func stageDirectionsAreShownButNotRead() {
        let line = "Buongiorno [pausa lunga] a tutti [sorridi]."
        #expect(ScriptMarkup.words(in: line) == ["buongiorno", "a", "tutti"])
        let directions = ScriptMarkup.tokens(in: line).filter(\.isDirection).map(\.text)
        #expect(directions == ["[pausa", "lunga]", "[sorridi]."])
    }

    @Test(arguments: ["* Primo punto", "- Primo punto", "• Primo punto"])
    func listBulletsAreDropped(line: String) {
        #expect(ScriptMarkup.plainText(line) == "Primo punto")
        #expect(ScriptMarkup.tokens(in: line).allSatisfy { !$0.isItalic })
    }

    @Test func stylesStopAtTheEndOfTheLine() {
        let script = ParsedScript("Inizio **senza chiusura\nRiga normale")
        #expect(ScriptMarkup.tokens(in: script.lines[1].text).allSatisfy { !$0.isBold })
        #expect(script.words == ["inizio", "senza", "chiusura", "riga", "normale"])
    }

    @Test func parsedScriptSkipsDirectionsInItsWords() {
        #expect(ParsedScript("Ciao [respira] mondo").words == ["ciao", "mondo"])
    }
}
