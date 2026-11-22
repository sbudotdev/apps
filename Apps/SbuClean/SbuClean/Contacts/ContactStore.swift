import Foundation

/// The address book as the duplicate finder uses it, so the model runs in tests without Contacts.
nonisolated protocol ContactStore: Sendable {
    /// The access the user gave, without asking.
    func currentAccess() -> ContactAccess

    /// Asks for access the first time; afterwards returns the current one.
    func requestAccess() async -> ContactAccess

    /// Every contact the app can read.
    func fetchContacts() async throws -> [ContactCard]

    /// The contacts as a vCard file, the backup written before a merge.
    func vCard(of ids: [String]) async throws -> Data

    /// Adds the numbers and addresses to the kept contact and deletes the others.
    func apply(_ merge: DuplicateContacts.Merge) async throws
}
