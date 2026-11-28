import XCTest

extension XCUIApplication {
    /// `performAccessibilityAudit`, but on the slow CI runners the audit can run out of time before
    /// it reports anything (`Code=-56 "Audit failed to complete in time"`, SBU-279, as SBU-399 for
    /// SbuNoise): then it starts again on the same screen, up to `attempts` times.
    /// A whole audit always runs; a timeout is never a pass.
    @MainActor
    func performAccessibilityAuditRetryingTimeouts(
        for types: XCUIAccessibilityAuditType,
        attempts: Int = 3,
        _ issueHandler: @escaping (XCUIAccessibilityAuditIssue) throws -> Bool
    ) throws {
        for attempt in 1...attempts {
            do {
                try performAccessibilityAudit(for: types, issueHandler)
                return
            } catch let error as NSError
                where error.domain == "com.apple.xcode.xctest.accessibilityAudit" && error.code == -56 && attempt < attempts {
                XCTContext.runActivity(named: "Audit out of time, attempt \(attempt) of \(attempts): again") { _ in }
            }
        }
    }
}
