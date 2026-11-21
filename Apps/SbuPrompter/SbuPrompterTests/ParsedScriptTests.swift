import Testing
@testable import SbuPrompter

struct ParsedScriptTests {
    let text = """
    Introduzione senza titolo.

    # Apertura
    Ciao a tutti.
    ---
    Seconda parte qui.
    ## Chiusura
    Grazie, ciao.
    """

    @Test func headingsAndSeparatorsBecomeCues() {
        let script = ParsedScript(text)
        #expect(script.cues.map(\.title) == ["Apertura", nil, "Chiusura"])
        #expect(script.cues.map(\.lineIndex) == [2, 4, 6])
    }

    @Test func headingsAreNotPartOfTheWordsToRead() {
        let script = ParsedScript(text)
        #expect(!script.words.contains("apertura"))
        #expect(script.words.first == "introduzione")
        #expect(script.lines[2].kind == .heading)
        #expect(script.lines[2].text == "Apertura")
        #expect(script.lines[4].kind == .separator)
    }

    @Test func cuesPointAtTheNextWordToRead() {
        let script = ParsedScript(text)
        // "introduzione senza titolo" are words 0...2.
        #expect(script.cues[0].wordIndex == 3)
        #expect(script.words[script.cues[1].wordIndex] == "seconda")
    }

    @Test func lineWordRangesCoverEveryWordOnce() {
        let script = ParsedScript(text)
        let total = script.lines.map(\.wordRange.count).reduce(0, +)
        #expect(total == script.words.count)
        #expect(script.line(containingWord: 3) == 3)
        #expect(script.line(containingWord: script.words.count) == script.lines.count - 1)
    }

    @Test(arguments: ["---", "***", "___", "===", "  -----  "])
    func separatorsNeedThreeOrMoreOfTheSameMark(_ line: String) {
        #expect(ParsedScript("a\n\(line)\nb").cues.count == 1)
    }

    @Test(arguments: ["--", "-*-", "#hashtag nel testo? no: questo è un titolo"])
    func otherLinesAreNotSeparators(_ line: String) {
        let cues = ParsedScript("a\n\(line)\nb").cues
        #expect(cues.allSatisfy { $0.title != nil })
    }

    @Test func cueNavigation() {
        let script = ParsedScript(text)
        #expect(script.cueIndex(atLine: 0) == nil)
        #expect(script.cueIndex(atLine: 3) == 0)
        #expect(script.cueIndex(atLine: 7) == 2)
        #expect(script.nextCue(afterLine: 0) == 0)
        #expect(script.nextCue(afterLine: 3) == 1)
        #expect(script.nextCue(afterLine: 7) == nil)
        #expect(script.previousCue(beforeLine: 7) == 1)
        #expect(script.previousCue(beforeLine: 2) == nil)
    }

    @Test func untitledScriptHasNoCues() {
        #expect(ParsedScript("solo testo\naltra riga").cues.isEmpty)
    }
}
