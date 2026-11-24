nonisolated struct Settings: Codable, Equatable, Sendable {
    static let currentVersion = 1

    var version = Settings.currentVersion
    var layout: BarLayout

    init(layout: BarLayout = BarLayout()) {
        self.layout = layout
    }
}
