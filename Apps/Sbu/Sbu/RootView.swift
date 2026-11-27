import LevelTool
import MoonTool
import SubscriptionsTool
import SwiftUI

struct RootView: View {
    var body: some View {
        TabView { LevelTool(); MoonTool(); SubscriptionsTool() }
    }
}
