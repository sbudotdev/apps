import SwiftUI

@main
struct SbuPrompterRemoteApp: App {
    @State private var model = RemoteModel()

    var body: some Scene {
        WindowGroup {
            RootView(model: model)
        }
    }
}
