import Testing
@testable import SbuPrompter

/// One script per language; the same scenarios run on both.
nonisolated struct AlignerCase: Sendable, CustomTestStringConvertible {
    let language: String
    let script: String
    let testDescription: String

    init(_ language: String, _ script: String) {
        self.language = language
        self.script = script
        testDescription = language
    }

    var words: [String] { TextNormalizer.words(in: script) }
}

nonisolated let alignerCases = [
    AlignerCase("it", "Buongiorno a tutti, oggi vi racconto come ho costruito una casa sull'albero in tre giorni con il mio cane e il mio gatto."),
    AlignerCase("en", "Good morning everyone, today I will tell you how I built a tree house in three days with my dog and my cat and my bird."),
]

struct ScriptAlignerTests {
    private func spoken(_ text: String) -> [String] { TextNormalizer.words(in: text) }

    @Test(arguments: alignerCases)
    func followsWordByWordReading(_ c: AlignerCase) {
        var aligner = ScriptAligner(script: c.words)
        var transcript: [String] = []
        for (index, word) in c.words.enumerated() {
            transcript.append(word)
            #expect(aligner.update(spoken: transcript) == index + 1)
        }
    }

    @Test(arguments: alignerCases)
    func jumpsAheadWhenWordsAreSkipped(_ c: AlignerCase) {
        var aligner = ScriptAligner(script: c.words)
        // First two words, then skip five, then read three.
        let read = Array(c.words[0..<2]) + Array(c.words[7..<10])
        #expect(aligner.update(spoken: read) == 10)
    }

    @Test(arguments: alignerCases)
    func neverGoesBack(_ c: AlignerCase) {
        var aligner = ScriptAligner(script: c.words)
        _ = aligner.update(spoken: Array(c.words[0..<8]))
        #expect(aligner.position == 8)
        // Re-reading the opening must not rewind.
        #expect(aligner.update(spoken: Array(c.words[0..<8]) + Array(c.words[0..<3])) == 8)
    }

    @Test(arguments: alignerCases)
    func ignoresImprovisedWordsThenResumes(_ c: AlignerCase) {
        var aligner = ScriptAligner(script: c.words)
        var transcript = Array(c.words[0..<5])
        _ = aligner.update(spoken: transcript)
        let aside = c.language == "it" ? "scusate mi sono perso un attimo" : "sorry folks I lost my place"
        transcript += spoken(aside)
        #expect(aligner.update(spoken: transcript) == 5)
        transcript += Array(c.words[5..<7])
        #expect(aligner.update(spoken: transcript) == 7)
    }

    @Test(arguments: alignerCases)
    func ignoresWordsFarBeyondTheWindow(_ c: AlignerCase) {
        var aligner = ScriptAligner(script: c.words, window: 5)
        // Words 15...18 exist but are outside the 5-word window ahead.
        #expect(aligner.update(spoken: Array(c.words[15..<19])) == 0)
    }

    @Test(arguments: [
        ("it", "e il mio gatto e il mio cane", "e il mio", 3),
        ("en", "and my cat and my dog and my bird", "and my", 2),
    ])
    func repeatedWordsDoNotJumpToALaterCopy(language: String, script: String, said: String, expected: Int) {
        var aligner = ScriptAligner(script: TextNormalizer.words(in: script))
        #expect(aligner.update(spoken: spoken(said)) == expected)
    }

    @Test(arguments: [
        ("it", "costa 3 euro al giorno", "costa tre euro", 3),
        ("en", "it costs 20 dollars a day", "it costs twenty dollars", 4),
        ("it", "siamo in dieci persone", "siamo in 10 persone", 4),
    ])
    func numbersMatchDigitsAndWords(language: String, script: String, said: String, expected: Int) {
        var aligner = ScriptAligner(script: TextNormalizer.words(in: script))
        #expect(aligner.update(spoken: spoken(said)) == expected)
    }

    @Test(arguments: [
        ("it", "oggi costruiamo una casetta", "oggi costruiano una", 3),
        ("en", "today we build a treehouse", "today we built a", 4),
    ])
    func toleratesSmallRecognitionErrors(language: String, script: String, said: String, expected: Int) {
        var aligner = ScriptAligner(script: TextNormalizer.words(in: script))
        #expect(aligner.update(spoken: spoken(said)) == expected)
    }

    @Test func aSingleWordFarAheadIsNotEnough() {
        var aligner = ScriptAligner(script: TextNormalizer.words(in: "uno due tre quattro cinque gatto sei"))
        #expect(aligner.update(spoken: ["gatto"]) == 0)
    }

    @Test func resetMovesThePosition() {
        var aligner = ScriptAligner(script: TextNormalizer.words(in: "a b c d e f"))
        aligner.reset(to: 4)
        #expect(aligner.position == 4)
        aligner.reset(to: 99)
        #expect(aligner.position == 6)
    }

    @Test func emptyScriptStaysAtZero() {
        var aligner = ScriptAligner(script: [])
        #expect(aligner.update(spoken: ["ciao"]) == 0)
    }
}
