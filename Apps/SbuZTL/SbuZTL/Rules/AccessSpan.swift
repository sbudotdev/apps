import Foundation

/// A stretch of one day with one answer.
nonisolated struct AccessSpan: Sendable, Equatable, Identifiable {
    var id: Int { startMinute }
    let startMinute: Int
    let endMinute: Int
    let access: Access
}
