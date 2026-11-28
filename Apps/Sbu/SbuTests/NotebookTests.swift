import Foundation
import Testing
@testable import Sbu

struct NotebookTests {
    private let defaults: UserDefaults

    init() {
        let suite = "NotebookTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.removePersistentDomain(forName: suite)
    }

    @Test func startsEmptyWithEveryToolToAdd() {
        let notebook = Notebook(defaults: defaults)
        #expect(notebook.tools.isEmpty)
        #expect(notebook.available == Tool.allCases)
    }

    @Test func addingPutsTheToolLastAndOnlyOnce() {
        let notebook = Notebook(defaults: defaults)
        notebook.add(.moon)
        notebook.add(.level)
        notebook.add(.moon)
        #expect(notebook.tools == [.moon, .level])
        #expect(notebook.available == [.subscriptions])
    }

    @Test func removingGivesTheToolBackToAdd() {
        let notebook = Notebook(defaults: defaults)
        Tool.allCases.forEach(notebook.add)
        notebook.remove(atOffsets: IndexSet(integer: 1))
        #expect(notebook.tools == [.level, .subscriptions])
        #expect(notebook.available == [.moon])
    }

    @Test func movingReordersThePages() {
        let notebook = Notebook(defaults: defaults)
        Tool.allCases.forEach(notebook.add)
        notebook.move(fromOffsets: IndexSet(integer: 2), toOffset: 0)
        #expect(notebook.tools == [.subscriptions, .level, .moon])
    }

    @Test func theChoiceSurvivesARelaunch() {
        let notebook = Notebook(defaults: defaults)
        notebook.add(.subscriptions)
        notebook.add(.level)
        notebook.move(fromOffsets: IndexSet(integer: 1), toOffset: 0)
        notebook.add(.moon)
        notebook.remove(atOffsets: IndexSet(integer: 2))
        #expect(Notebook(defaults: defaults).tools == [.level, .subscriptions])
    }

    @Test func aToolThisBuildDoesNotKnowIsDropped() {
        defaults.set(["moon", "scanner", "moon", "level"], forKey: Notebook.storageKey)
        #expect(Notebook(defaults: defaults).tools == [.moon, .level])
    }
}

struct ToolTests {
    @Test(arguments: [
        ("sbu://level", Tool.level),
        ("sbu://subscriptions", .subscriptions),
        ("sbu://scanner", nil),
        ("https://level", nil),
    ] as [(String, Tool?)])
    func aLinkOpensItsTool(link: String, tool: Tool?) throws {
        #expect(Tool(url: try #require(URL(string: link))) == tool)
    }
}
