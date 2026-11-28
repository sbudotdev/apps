import AppIntents
import SwiftData
import SwiftUI

/// Sbu Subscriptions as a page of the notebook: the app's own root, with what its `App` gives it (ADR-0027).
///
/// shortcut: the store is Sbu's own, on this iPhone only: no App Group, no iCloud sync and no shared lists,
/// which need entitlements Sbu doesn't have yet. Upgrade when the tool leaves the spike (ADR-0027, Passi futuri).
public struct SubscriptionsTool: View {
    @State private var sharing = ListSharing(outbox: nil)
    @State private var received = ReceivedLists(store: .shared, inbox: nil)

    public init() {}

    public var body: some View {
        RootView()
            .environment(Self.router)
            .environment(sharing)
            .environment(received)
            .modelContainer(Self.container)
    }

    /// Shared with Siri, Shortcuts and Spotlight, which leave the route here for the tool to follow.
    private static let router = AppRouter()

    /// Whether Siri, Shortcuts or Spotlight asked for a subscription, the calendar or a new one: Sbu then opens the tool.
    public static var hasPendingRoute: Bool { router.pending != nil }

    /// What the tool's App Intents need, as `SbuSubscriptionsApp.init` does: call it in Sbu's `init`, which also runs
    /// for an intent with no window. It opens the store at launch, as the app does: a local file, no permission.
    public static func registerIntentDependencies() {
        let container = container
        let router = router
        AppDependencyManager.shared.add(dependency: container)
        AppDependencyManager.shared.add(dependency: router)
    }

    /// Opened at Sbu's launch by `registerIntentDependencies`.
    // ponytail: no recovery screen, as in the app: a store that can't open is a bug, never a reason to start empty.
    private static let container: ModelContainer = {
        let defaults = UserDefaults.standard
        // Screenshots show made-up subscriptions; UI tests start from an empty store of their own.
        if defaults.bool(forKey: "FASTLANE_SNAPSHOT") { return .preview }
        if defaults.bool(forKey: "SBU_EMPTY_STORE"), let container = try? ModelContainer.subscriptions(inMemory: true) {
            try? CategorySeeder.seed(container.mainContext)
            return container
        }
        do {
            let folder = URL.applicationSupportDirectory
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let schema = Schema(versionedSchema: SubscriptionsSchemaV1.self)
            let configuration = ModelConfiguration(schema: schema, url: folder.appending(path: "Subscriptions.store"), cloudKitDatabase: .none)
            let container = try ModelContainer(for: schema, migrationPlan: SubscriptionsMigrationPlan.self, configurations: configuration)
            try CategorySeeder.seed(container.mainContext)
            try Subscription.repairDuplicateIDs(container.mainContext)
            return container
        } catch {
            fatalError("Subscriptions store failed to open: \(error)")
        }
    }()
}
