import Testing
@testable import SbuPrompter

struct ScriptInsertionTests {
    @Test(arguments: [
        // Text, offset, expected text, expected cursor.
        ("", 0, "# \n", 2),
        ("Ciao", 4, "Ciao\n# \n", 7),
        ("Uno\nDue", 4, "Uno\n# \nDue", 6),
        ("Uno\nDue", 3, "Uno\n# \nDue", 6),
        ("Uno", 99, "Uno\n# \n", 6),
    ])
    func sectionGoesOnItsOwnLine(text: String, offset: Int, expected: String, cursor: Int) {
        let result = ScriptInsertion.section.apply(to: text, at: offset)
        #expect(result.text == expected)
        #expect(result.cursor == cursor)
    }

    @Test func dividerBecomesABreakInTheParsedScript() {
        let result = ScriptInsertion.divider.apply(to: "Prima parte.", at: 12)
        #expect(result.text == "Prima parte.\n---\n")
        #expect(ParsedScript(result.text).cues.count == 1)
    }
}
