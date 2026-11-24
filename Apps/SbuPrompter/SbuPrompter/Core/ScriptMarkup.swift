/// The little markup a script line may carry, as people write it in Markdown or Word:
/// `**bold**`, `*italic*`, and `[stage directions]` that are shown but not read aloud.
/// Styles never cross a line. A lone `*` or `-` opening the line is a list bullet and is dropped.
nonisolated enum ScriptMarkup {
    nonisolated struct Token: Sendable, Equatable {
        /// As shown, without the `*` marks.
        let text: String
        /// For voice following; empty for punctuation and stage directions.
        let normalized: String
        var isBold = false
        var isItalic = false
        var isDirection = false
    }

    static func tokens(in line: String) -> [Token] {
        var result: [Token] = []
        var bold = false, italic = false, direction = false
        for (index, raw) in line.split(whereSeparator: \.isWhitespace).enumerated() {
            if index == 0, raw == "*" || raw == "-" || raw == "•" { continue }
            var text = ""
            var tokenBold = false, tokenItalic = false, tokenDirection = false
            let characters = Array(raw)
            var position = 0
            while position < characters.count {
                let character = characters[position]
                if character == "*" {
                    var run = 0
                    while position < characters.count, characters[position] == "*" { run += 1; position += 1 }
                    if run >= 2 { bold.toggle() } else { italic.toggle() }
                    continue
                }
                if character == "[" { direction = true }
                text.append(character)
                tokenBold = tokenBold || bold
                tokenItalic = tokenItalic || italic
                tokenDirection = tokenDirection || direction
                if character == "]" { direction = false }
                position += 1
            }
            guard !text.isEmpty else { continue }
            result.append(Token(text: text, normalized: tokenDirection ? "" : TextNormalizer.normalize(text),
                                isBold: tokenBold, isItalic: tokenItalic, isDirection: tokenDirection))
        }
        return result
    }

    /// The words to read, in order: what voice following matches.
    static func words(in line: String) -> [String] {
        tokens(in: line).compactMap { $0.normalized.isEmpty ? nil : $0.normalized }
    }

    /// The line without marks, for the iPhone remote.
    static func plainText(_ line: String) -> String {
        tokens(in: line).map(\.text).joined(separator: " ")
    }
}
