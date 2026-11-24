/// A section title or a break typed into the script at the cursor, always on a line of its own.
nonisolated enum ScriptInsertion: Sendable {
    case section
    case divider

    /// The text that goes in, and where the cursor lands inside it.
    private var snippet: (text: String, cursor: Int) {
        switch self {
        case .section: ("# \n", 2) // the cursor waits after "# " for the title
        case .divider: ("---\n", 4)
        }
    }

    /// Inserts at character `offset` of `text`; returns the new text and the cursor's character offset.
    func apply(to text: String, at offset: Int) -> (text: String, cursor: Int) {
        let index = text.index(text.startIndex, offsetBy: min(max(offset, 0), text.count))
        var (insert, cursor) = snippet
        if index > text.startIndex, text[text.index(before: index)] != "\n" {
            insert = "\n" + insert
            cursor += 1
        }
        if index < text.endIndex, text[index] == "\n", insert.hasSuffix("\n") {
            insert.removeLast() // the line already ends here
        }
        var result = text
        result.insert(contentsOf: insert, at: index)
        return (result, text.distance(from: text.startIndex, to: index) + cursor)
    }
}
