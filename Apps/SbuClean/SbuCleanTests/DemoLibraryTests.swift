import Foundation
import Testing
@testable import SbuClean

/// The demo library the screenshots and UI tests run on shows every kind of group and list.
struct DemoLibraryTests {
    @Test func theDemoHasEveryKindOfGroupAndList() async {
        let model = CleanModel(library: DemoLibrary(), directory: Fixture.directory(), readStorage: { nil },
                               contacts: ContactsModel(store: DemoContactStore()))
        await model.reload()
        await model.waitForScan()

        #expect(Set(model.groups.map(\.kind)) == Set(GroupKind.allCases))
        #expect(model.items(in: .blurry).count == 2)
        #expect(model.items(in: .chats).count == 4)
    }
}
