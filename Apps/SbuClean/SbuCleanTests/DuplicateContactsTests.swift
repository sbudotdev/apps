import Foundation
import Testing
@testable import SbuClean

struct DuplicateContactsTests {
    @Test func theSameNumberInAnotherFormatIsTheSamePerson() {
        let contacts = [
            ContactCard(id: "a", name: "Giulia Rossi", phones: ["+39 333 123 4567"], emails: ["g@example.com"]),
            ContactCard(id: "b", name: "Giulia", phones: ["3331234567"]),
            ContactCard(id: "c", name: "Sara", phones: ["340 1112233"]),
        ]

        let groups = DuplicateContacts.groups(of: contacts)

        #expect(groups.map { $0.map(\.id) } == [["a", "b"]])
    }

    @Test(arguments: [("Marco Bianchi", "marco  bianchi"), ("Nicolò", "Nicolo")])
    func theSameNameIsTheSamePerson(first: String, second: String) {
        let groups = DuplicateContacts.groups(of: [ContactCard(id: "a", name: first), ContactCard(id: "b", name: second)])

        #expect(groups.count == 1)
    }

    @Test func aGroupThroughAnEmailJoinsAThirdThroughAName() {
        let contacts = [
            ContactCard(id: "a", name: "Luca", emails: ["LUCA@example.com"]),
            ContactCard(id: "b", name: "Luca Ferri", emails: ["luca@example.com"]),
            ContactCard(id: "c", name: "luca ferri"),
        ]

        #expect(DuplicateContacts.groups(of: contacts).first?.count == 3)
    }

    @Test func mergingKeepsTheFullestAndAddsWhatIsMissing() throws {
        let group = DuplicateContacts.groups(of: [
            ContactCard(id: "short", name: "Giulia", phones: ["333 1234567", "02 1234567"]),
            ContactCard(id: "full", name: "Giulia", phones: ["+39 333 123 4567"], emails: ["g@example.com", "giulia@example.com"]),
        ])[0]

        let merge = try #require(DuplicateContacts.merge(group))

        #expect(merge == DuplicateContacts.Merge(keep: "full", addedPhones: ["02 1234567"], addedEmails: [], delete: ["short"]))
    }

    @Test func mergingWritesTheBackupFirst() async throws {
        let directory = Fixture.directory()
        let model = ContactsModel(store: DemoContactStore(), backupDirectory: directory, now: { Fixture.date(10, 23) })
        await model.load()
        let before = model.duplicateCount

        let backup = try #require(await model.merge(try #require(model.groups.first)))

        #expect(FileManager.default.fileExists(atPath: backup.path))
        #expect(backup.pathExtension == "vcf")
        #expect(model.duplicateCount == before - 1)
    }
}
