import Foundation

/// An answer with its reason.
nonisolated struct Verdict: Sendable, Equatable {
    let access: Access
    let reason: LocalizedStringResource
    /// The act that says so, with the day someone last read it. `nil` for what the dataset alone tells.
    let source: RuleSource?
}
