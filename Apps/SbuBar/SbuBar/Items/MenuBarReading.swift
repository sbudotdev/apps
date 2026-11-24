protocol MenuBarReading: Sendable {
    /// Items of every running app, in any order; `ItemsModel` sorts them.
    func items() async -> [MenuBarItem]
}
