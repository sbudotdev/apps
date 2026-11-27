import SwiftUI

/// Sbu Level as a page of the notebook: the app's own root, unchanged (ADR-0027).
/// The camera is asked for only when you open the sight, as in the app.
public struct LevelTool: View {
    public init() {}

    public var body: some View {
        RootView()
    }
}
