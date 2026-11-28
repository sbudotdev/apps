import Foundation

extension Notebook {
    /// Every tool, in a notebook of its own that never touches yours.
    static var preview: Notebook {
        let notebook = Notebook(defaults: UserDefaults(suiteName: "preview") ?? .standard)
        Tool.allCases.forEach(notebook.add)
        return notebook
    }
}
