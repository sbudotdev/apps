import SwiftUI

/// Sbu Moon as a page of the notebook: the app's own root, unchanged (ADR-0027).
/// Notifications are asked for only when you turn on a phase alert, as in the app.
public struct MoonTool: View {
    public init() {}

    public var body: some View {
        RootView()
    }
}
