import Foundation

nonisolated struct SettingsStore: Sendable {
    let directory: URL
    private var file: URL { directory.appending(path: "settings.json") }
    private var backup: URL { directory.appending(path: "settings.backup.json") }

    init(directory: URL) {
        self.directory = directory
    }

    func load() -> Settings {
        for url in [file, backup] {
            if let data = try? Data(contentsOf: url),
               let settings = try? JSONDecoder().decode(Settings.self, from: data) {
                return settings
            }
        }
        return Settings()
    }

    func save(_ settings: Settings) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        // Only a readable file becomes the backup, so a corrupt one never overwrites a good copy.
        if let current = try? Data(contentsOf: file),
           (try? JSONDecoder().decode(Settings.self, from: current)) != nil {
            try current.write(to: backup, options: .atomic)
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(settings).write(to: file, options: .atomic)
    }
}
