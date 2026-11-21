import Foundation
import Testing
@testable import SbuSeasons

/// «Salva…» sopra un file che c'è già (SBU-205): se la copia non riesce, il file di prima resta.
struct ToySharingTests {
    private let folder = FileManager.default.temporaryDirectory.appending(path: "ToySharingTests-\(UUID().uuidString)")

    private func file(_ name: String, _ text: String) throws -> URL {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let url = folder.appending(path: name)
        try Data(text.utf8).write(to: url)
        return url
    }

    @Test func savingOverAFileReplacesItAndKeepsTheOneToShare() throws {
        let shared = try file("nuovo.sbuseasons", "nuovo")
        let target = try file("vecchio.sbuseasons", "vecchio")
        try ToySharing.place(shared, at: target)
        #expect(try String(contentsOf: target, encoding: .utf8) == "nuovo")
        #expect(try String(contentsOf: shared, encoding: .utf8) == "nuovo", "il menu può ancora mandarlo")
    }

    @Test func savingWhereThereIsNothingCopies() throws {
        let shared = try file("nuovo.sbuseasons", "nuovo")
        let target = folder.appending(path: "altro.sbuseasons")
        try ToySharing.place(shared, at: target)
        #expect(try String(contentsOf: target, encoding: .utf8) == "nuovo")
    }

    @Test func aFailedCopyLeavesTheOldFile() throws {
        let missing = folder.appending(path: "sparito.sbuseasons")
        let target = try file("vecchio.sbuseasons", "vecchio")
        #expect(throws: (any Error).self) { try ToySharing.place(missing, at: target) }
        #expect(try String(contentsOf: target, encoding: .utf8) == "vecchio")
    }

    @Test func aFailedReplaceLeavesNoTemporaryCopy() throws {
        let shared = try file("nuovo.sbuseasons", "nuovo")
        let locked = folder.appending(path: "bloccata")
        try FileManager.default.createDirectory(at: locked, withIntermediateDirectories: true)
        let target = locked.appending(path: "vecchio.sbuseasons")
        try Data("vecchio".utf8).write(to: target)
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: locked.path)
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: locked.path) }

        #expect(throws: (any Error).self) { try ToySharing.place(shared, at: target) }
        #expect(try String(contentsOf: target, encoding: .utf8) == "vecchio")
        let left = try FileManager.default.contentsOfDirectory(atPath: folder.path).sorted()
        #expect(left == ["bloccata", "nuovo.sbuseasons"], "nessuna copia temporanea rimasta")
    }
}
