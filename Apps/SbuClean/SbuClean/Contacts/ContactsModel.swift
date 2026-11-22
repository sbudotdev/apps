import Foundation
import Observation

/// The duplicate contacts: access, the groups found, and the merge with its backup first.
///
/// Every merge writes the group's contacts as a vCard file in the app's Documents, which the Files
/// app shows in the Sbu Clean folder: a merged contact can always be brought back.
@Observable
final class ContactsModel {
    let store: any ContactStore

    private(set) var access: ContactAccess
    private(set) var groups: [[ContactCard]] = []
    private(set) var hasLoaded = false
    /// Why the last read or merge failed, for the screen to say.
    private(set) var failure: String?

    @ObservationIgnored private let backupDirectory: URL
    @ObservationIgnored private let now: @Sendable () -> Date

    /// Creates the model.
    /// - Parameters:
    ///   - store: Contacts, or a fake in tests and previews.
    ///   - backupDirectory: Where backups go; the app's Documents when `nil`.
    ///   - now: The clock, for the backup's name.
    init(store: any ContactStore, backupDirectory: URL? = nil, now: @escaping @Sendable () -> Date = { .now }) {
        self.store = store
        self.backupDirectory = backupDirectory ?? URL.documentsDirectory
        self.now = now
        access = store.currentAccess()
    }

    /// How many contacts would go away by merging every group.
    var duplicateCount: Int {
        groups.reduce(0) { $0 + $1.count - 1 }
    }

    /// Asks for access, then reads the contacts when granted.
    func requestAccess() async {
        access = await store.requestAccess()
        await load()
    }

    /// Reads the contacts and finds the groups.
    func load() async {
        access = store.currentAccess()
        guard access == .allowed else { return }

        do {
            groups = DuplicateContacts.groups(of: try await store.fetchContacts())
            failure = nil
        } catch {
            failure = error.localizedDescription
        }
        hasLoaded = true
    }

    /// Saves the group as a vCard backup, merges it, and reads the contacts again. Returns the
    /// backup's file, or `nil` when nothing was merged.
    @discardableResult
    func merge(_ group: [ContactCard]) async -> URL? {
        guard let merge = DuplicateContacts.merge(group) else { return nil }

        do {
            let backup = try await writeBackup(of: group)
            try await store.apply(merge)
            await load()
            return backup
        } catch {
            failure = error.localizedDescription
            return nil
        }
    }

    private func writeBackup(of group: [ContactCard]) async throws -> URL {
        let data = try await store.vCard(of: group.map(\.id))
        let folder = backupDirectory.appending(path: String(localized: "Copie dei contatti"), directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let stamp = now().formatted(.iso8601.year().month().day().time(includingFractionalSeconds: false).timeSeparator(.omitted))
        let name = (group.first?.name.isEmpty ?? true) ? String(localized: "Contatto") : group[0].name
        let file = folder.appending(path: "\(stamp) \(name.replacing("/", with: "-")).vcf")
        try data.write(to: file, options: .atomic)
        return file
    }
}
