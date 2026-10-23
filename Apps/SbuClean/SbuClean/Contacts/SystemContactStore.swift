import Contacts

/// The real address book, through Contacts, on the device only.
nonisolated final class SystemContactStore: ContactStore {
    private static var keys: [any CNKeyDescriptor] {
        [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
        ]
    }

    func currentAccess() -> ContactAccess {
        ContactAccess(status: CNContactStore.authorizationStatus(for: .contacts))
    }

    func requestAccess() async -> ContactAccess {
        _ = try? await CNContactStore().requestAccess(for: .contacts)
        return currentAccess()
    }

    // Off the main actor: callers are views and the main-actor model.
    @concurrent
    func fetchContacts() async throws -> [ContactCard] {
        var cards: [ContactCard] = []
        let request = CNContactFetchRequest(keysToFetch: Self.keys)
        try CNContactStore().enumerateContacts(with: request) { contact, _ in
            cards.append(ContactCard(
                id: contact.identifier,
                name: CNContactFormatter.string(from: contact, style: .fullName) ?? "",
                phones: contact.phoneNumbers.map(\.value.stringValue),
                emails: contact.emailAddresses.map { $0.value as String }
            ))
        }
        return cards
    }

    // Off the main actor: callers are views and the main-actor model.
    @concurrent
    func vCard(of ids: [String]) async throws -> Data {
        let predicate = CNContact.predicateForContacts(withIdentifiers: ids)
        let contacts = try CNContactStore().unifiedContacts(matching: predicate, keysToFetch: [CNContactVCardSerialization.descriptorForRequiredKeys()])
        return try CNContactVCardSerialization.data(with: contacts)
    }

    // Off the main actor: callers are views and the main-actor model.
    @concurrent
    func apply(_ merge: DuplicateContacts.Merge) async throws {
        let store = CNContactStore()
        let keys = Self.keys
        let all = try store.unifiedContacts(matching: CNContact.predicateForContacts(withIdentifiers: [merge.keep] + merge.delete), keysToFetch: keys)
        guard let kept = all.first(where: { $0.identifier == merge.keep })?.mutableCopy() as? CNMutableContact else { throw CocoaError(.fileNoSuchFile) }

        kept.phoneNumbers += merge.addedPhones.map { CNLabeledValue(label: CNLabelPhoneNumberMobile, value: CNPhoneNumber(stringValue: $0)) }
        kept.emailAddresses += merge.addedEmails.map { CNLabeledValue(label: CNLabelHome, value: $0 as NSString) }
        let request = CNSaveRequest()
        request.update(kept)
        for contact in all where merge.delete.contains(contact.identifier) {
            if let deleted = contact.mutableCopy() as? CNMutableContact {
                request.delete(deleted)
            }
        }
        try store.execute(request)
    }
}
