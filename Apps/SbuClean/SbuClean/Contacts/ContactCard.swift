/// A contact as the duplicate finder sees it: who it is and how to reach them.
nonisolated struct ContactCard: Identifiable, Hashable, Sendable {
    /// The Contacts identifier.
    let id: String
    var name: String
    var phones: [String] = []
    var emails: [String] = []

    /// How much the contact holds: the fullest one is kept when merging.
    var richness: Int {
        phones.count + emails.count + (name.isEmpty ? 0 : 1)
    }
}
