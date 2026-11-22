import Foundation

/// Finds contacts that are the same person, and plans how to merge them.
///
/// Two contacts are the same person when they share a phone number (the last nine digits, so
/// "+39 333 1234567" and "3331234567" match), an email address, or a full name. A group keeps
/// its fullest contact; the others' numbers and addresses join it, and then they go.
nonisolated enum DuplicateContacts {
    /// How many trailing digits identify a phone number across formats and prefixes.
    static let phoneDigits = 9

    /// Groups of two or more contacts that are the same person, the fullest first.
    static func groups(of contacts: [ContactCard]) -> [[ContactCard]] {
        var union = UnionFind(count: contacts.count)
        var firstByKey: [String: Int] = [:]
        for (index, contact) in contacts.enumerated() {
            for key in keys(of: contact) {
                if let first = firstByKey[key] {
                    union.join(first, index)
                } else {
                    firstByKey[key] = index
                }
            }
        }
        return union.groups().map { indices in
            indices.map { contacts[$0] }.sorted { $0.richness > $1.richness }
        }
    }

    /// What merging a group does: the contact kept, what it gains, the contacts deleted.
    nonisolated struct Merge: Equatable, Sendable {
        var keep: String
        var addedPhones: [String]
        var addedEmails: [String]
        var delete: [String]
    }

    /// The merge of a group made by `groups(of:)`.
    static func merge(_ group: [ContactCard]) -> Merge? {
        guard let kept = group.first, group.count > 1 else { return nil }

        var phones = Set(kept.phones.map(phoneKey))
        var emails = Set(kept.emails.map(emailKey))
        var addedPhones: [String] = []
        var addedEmails: [String] = []
        for other in group.dropFirst() {
            for phone in other.phones where phones.insert(phoneKey(phone)).inserted {
                addedPhones.append(phone)
            }
            for email in other.emails where emails.insert(emailKey(email)).inserted {
                addedEmails.append(email)
            }
        }
        return Merge(keep: kept.id, addedPhones: addedPhones, addedEmails: addedEmails, delete: group.dropFirst().map(\.id))
    }

    private static func keys(of contact: ContactCard) -> [String] {
        var keys: [String] = []
        let name = contact.name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .split(whereSeparator: \.isWhitespace).joined(separator: " ")
        if !name.isEmpty {
            keys.append("name:\(name)")
        }
        keys += contact.phones.map(phoneKey).filter { $0.count >= 6 }.map { "phone:\($0)" }
        keys += contact.emails.map(emailKey).filter { !$0.isEmpty }.map { "email:\($0)" }
        return keys
    }

    private static func phoneKey(_ phone: String) -> String {
        String(phone.filter(\.isNumber).suffix(phoneDigits))
    }

    private static func emailKey(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespaces).lowercased()
    }
}
