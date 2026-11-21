/// A script split into lines, the words to read and the cues (sections).
/// A line starting with `#` is a section title; a line of three or more `-`, `*`, `_` or `=` is an untitled break.
nonisolated struct ParsedScript: Sendable, Equatable {
    nonisolated struct Line: Sendable, Equatable {
        enum Kind: Sendable { case text, heading, separator }
        let text: String
        let kind: Kind
        /// Indices into `words`; empty for titles, breaks and blank lines.
        let wordRange: Range<Int>
    }

    nonisolated struct Cue: Sendable, Equatable {
        let title: String?
        let lineIndex: Int
        /// The first word to read after the cue.
        let wordIndex: Int
    }

    let lines: [Line]
    let words: [String]
    let cues: [Cue]

    init(_ text: String) {
        var lines: [Line] = []
        var words: [String] = []
        var cues: [Cue] = []
        for raw in text.split(separator: "\n", omittingEmptySubsequences: false) {
            let trimmed = raw.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("#") {
                let title = String(trimmed.drop(while: { $0 == "#" })).trimmingCharacters(in: .whitespaces)
                cues.append(Cue(title: title, lineIndex: lines.count, wordIndex: words.count))
                lines.append(Line(text: title, kind: .heading, wordRange: words.count..<words.count))
            } else if Self.isSeparator(trimmed) {
                cues.append(Cue(title: nil, lineIndex: lines.count, wordIndex: words.count))
                lines.append(Line(text: "", kind: .separator, wordRange: words.count..<words.count))
            } else {
                let lineWords = TextNormalizer.words(in: trimmed)
                lines.append(Line(text: String(raw), kind: .text, wordRange: words.count..<words.count + lineWords.count))
                words += lineWords
            }
        }
        self.lines = lines
        self.words = words
        self.cues = cues
    }

    private static func isSeparator(_ line: String) -> Bool {
        guard line.count >= 3, let first = line.first, "-*_=".contains(first) else { return false }
        return line.allSatisfy { $0 == first }
    }

    /// The line holding the word at `index`; past the end, the last line.
    func line(containingWord index: Int) -> Int {
        lines.firstIndex { $0.wordRange.upperBound > index } ?? max(lines.count - 1, 0)
    }

    /// The cue whose section contains `line`, if any.
    func cueIndex(atLine line: Int) -> Int? {
        cues.lastIndex { $0.lineIndex <= line }
    }

    func nextCue(afterLine line: Int) -> Int? {
        cues.firstIndex { $0.lineIndex > line }
    }

    func previousCue(beforeLine line: Int) -> Int? {
        guard let current = cueIndex(atLine: line), current > 0 else { return nil }
        return current - 1
    }
}
