import Foundation

/// Turns script and speech text into comparable words: lowercase, no accents,
/// no punctuation, and spelled numbers as digits, so "tre" matches "3".
nonisolated enum TextNormalizer {
    static func words(in text: String) -> [String] {
        tokens(in: text).compactMap { $0.normalized.isEmpty ? nil : $0.normalized }
    }

    /// Every whitespace-separated token as written, with its normalized form (empty for punctuation).
    static func tokens(in text: String) -> [(text: Substring, normalized: String)] {
        text.split(whereSeparator: \.isWhitespace).map { ($0, normalize(String($0))) }
    }

    static func normalize(_ word: String) -> String {
        let folded = word.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: nil)
        let letters = String(folded.unicodeScalars.filter(CharacterSet.alphanumerics.contains))
        return numbers[letters] ?? letters
    }

    // shortcut: single-word numbers only; "twenty one" stays two words and relies on the fuzzy match.
    private static let numbers: [String: String] = {
        let italian = ["zero", "uno", "due", "tre", "quattro", "cinque", "sei", "sette", "otto", "nove", "dieci",
                       "undici", "dodici", "tredici", "quattordici", "quindici", "sedici", "diciassette", "diciotto", "diciannove", "venti"]
        let english = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten",
                       "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen", "twenty"]
        var table: [String: String] = [:]
        for (value, word) in italian.enumerated() { table[word] = String(value) }
        for (value, word) in english.enumerated() { table[word] = String(value) }
        let tens = [30: ("trenta", "thirty"), 40: ("quaranta", "forty"), 50: ("cinquanta", "fifty"), 60: ("sessanta", "sixty"),
                    70: ("settanta", "seventy"), 80: ("ottanta", "eighty"), 90: ("novanta", "ninety"),
                    100: ("cento", "hundred"), 1000: ("mille", "thousand")]
        for (value, words) in tens {
            table[words.0] = String(value)
            table[words.1] = String(value)
        }
        return table
    }()
}
