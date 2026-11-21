import Testing
@testable import SbuPrompter

struct TextNormalizerTests {
    @Test(arguments: [
        ("Perché", "perche"),
        ("città,", "citta"),
        ("«Ciao!»", "ciao"),
        ("L'aria", "laria"),
        ("Don't", "dont"),
        ("CAFÉ.", "cafe"),
        ("—", ""),
    ])
    func normalizesCaseAccentsAndPunctuation(word: String, expected: String) {
        #expect(TextNormalizer.normalize(word) == expected)
    }

    @Test(arguments: [
        ("tre", "3"), ("three", "3"), ("3", "3"),
        ("dieci", "10"), ("ten", "10"), ("venti", "20"), ("twenty", "20"),
        ("cento", "100"), ("hundred", "100"), ("zero", "0"),
    ])
    func spelledNumbersBecomeDigits(word: String, expected: String) {
        #expect(TextNormalizer.normalize(word) == expected)
    }

    @Test func splitsIntoWordsAndDropsPunctuationOnlyTokens() {
        #expect(TextNormalizer.words(in: "Ciao a tutti — oggi parliamo di 3 cose.") ==
            ["ciao", "a", "tutti", "oggi", "parliamo", "di", "3", "cose"])
    }

    @Test func emptyTextHasNoWords() {
        #expect(TextNormalizer.words(in: "  \n ").isEmpty)
    }
}
