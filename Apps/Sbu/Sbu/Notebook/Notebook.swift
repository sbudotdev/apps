import Foundation
import Observation

/// The pages of your notebook: the tools you added, in your order, kept in the defaults.
@Observable
final class Notebook {
    static let storageKey = "notebook.tools"

    private(set) var tools: [Tool] {
        didSet { defaults.set(tools.map(\.rawValue), forKey: Self.storageKey) }
    }

    /// The tools you can still add, in catalog order.
    var available: [Tool] {
        Tool.allCases.filter { !tools.contains($0) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        // A tool a later build removed, or the same one twice, never makes an empty page.
        var seen = Set<Tool>()
        tools = (defaults.stringArray(forKey: Self.storageKey) ?? [])
            .compactMap(Tool.init(rawValue:))
            .filter { seen.insert($0).inserted }
    }

    func add(_ tool: Tool) {
        guard !tools.contains(tool) else { return }
        tools.append(tool)
    }

    func remove(atOffsets offsets: IndexSet) {
        tools.remove(atOffsets: offsets)
    }

    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        tools.move(fromOffsets: source, toOffset: destination)
    }
}
