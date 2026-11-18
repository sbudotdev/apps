import XCTest

extension XCUIApplication {
    /// The accessibility audit with a retry when it runs out of time. On a busy CI Mac the audit
    /// gives up on a still screen ("Audit failed to complete in time", code -56); a real issue
    /// still reaches the handler on every attempt.
    @MainActor
    func performAccessibilityAuditRetryingTimeouts(
        for types: XCUIAccessibilityAuditType,
        _ handler: ((XCUIAccessibilityAuditIssue) throws -> Bool)? = nil
    ) throws {
        for attempt in 1...3 {
            do {
                try performAccessibilityAudit(for: types, handler)
                return
            } catch let error as NSError where error.domain == "com.apple.xcode.xctest.accessibilityAudit" && error.code == -56 && attempt < 3 {
                continue
            }
        }
    }
}
