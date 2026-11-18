#if DEBUG
import Foundation

/// The day the app believes it is, from the launch argument `-today 2026-12-25T12:00:00Z`: UI
/// tests and screenshots see the Christmas theme and game on any day. Debug builds only.
enum ForcedToday {
    static let date: Date? = UserDefaults.standard.string(forKey: "today").flatMap { try? Date($0, strategy: .iso8601) }
}
#endif
