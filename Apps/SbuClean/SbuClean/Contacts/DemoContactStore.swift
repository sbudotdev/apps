import Foundation
import os

/// A made-up address book for previews, UI tests and screenshots, with three people saved twice.
nonisolated final class DemoContactStore: ContactStore {
    private let contacts = OSAllocatedUnfairLock(initialState: [
        ContactCard(id: "c1", name: "Giulia Rossi", phones: ["+39 333 123 4567"], emails: ["giulia.rossi@example.com"]),
        ContactCard(id: "c2", name: "Giulia", phones: ["333 1234567"]),
        ContactCard(id: "c3", name: "Marco Bianchi", phones: ["+39 347 765 4321"]),
        ContactCard(id: "c4", name: "marco bianchi", emails: ["marco@example.com"]),
        ContactCard(id: "c5", name: "Idraulico", phones: ["02 4455 6677"]),
        ContactCard(id: "c6", name: "Luca Ferri idraulico", phones: ["+39 02 4455 6677"], emails: ["ferri@example.com"]),
        ContactCard(id: "c7", name: "Sara Conti", phones: ["+39 340 111 2233"]),
    ])

    func currentAccess() -> ContactAccess {
        .allowed
    }

    func requestAccess() async -> ContactAccess {
        .allowed
    }

    func fetchContacts() async throws -> [ContactCard] {
        contacts.withLock { $0 }
    }

    func vCard(of ids: [String]) async throws -> Data {
        Data("BEGIN:VCARD\nVERSION:3.0\nEND:VCARD\n".utf8)
    }

    func apply(_ merge: DuplicateContacts.Merge) async throws {
        contacts.withLock { contacts in
            if let index = contacts.firstIndex(where: { $0.id == merge.keep }) {
                contacts[index].phones += merge.addedPhones
                contacts[index].emails += merge.addedEmails
            }
            contacts.removeAll { merge.delete.contains($0.id) }
        }
    }
}
