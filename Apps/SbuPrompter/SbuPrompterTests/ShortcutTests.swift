import Testing
@testable import SbuPrompter

struct ShortcutTests {
    @Test func everyActionHasADistinctDefault() {
        let defaults = ShortcutAction.allCases.map(\.defaultCombo)
        #expect(Set(defaults).count == defaults.count)
    }

    @Test(arguments: [
        (ShortcutAction.togglePlay, PrompterCommand.togglePlay),
        (.faster, .faster), (.slower, .slower), (.nextCue, .nextCue),
        (.previousCue, .previousCue), (.toggleVisibility, .toggleVisibility), (.returnFromCue, .returnFromCue),
    ])
    func actionsMapToCommands(action: ShortcutAction, command: PrompterCommand) {
        #expect(action.command == command)
    }

    @Test func comboLabelShowsModifiersInSystemOrder() {
        let combo = KeyCombo(keyCode: 49, modifiers: [.command, .control, .option, .shift], key: "Spazio")
        #expect(combo.label == "⌃⌥⇧⌘Spazio")
    }

    @Test func combosNeedAModifierOtherThanShift() {
        #expect(KeyCombo(keyCode: 0, modifiers: [.shift], key: "A").isValidGlobal == false)
        #expect(KeyCombo(keyCode: 0, modifiers: [.option], key: "A").isValidGlobal)
    }
}
