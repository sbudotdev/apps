import Foundation
import SwiftData

/// A script in the library, saved on this Mac only.
@Model
final class Script {
    var id = UUID()
    var title: String
    var body: String
    var updatedAt: Date

    init(title: String, body: String, updatedAt: Date = .now) {
        self.title = title
        self.body = body
        self.updatedAt = updatedAt
    }
}
