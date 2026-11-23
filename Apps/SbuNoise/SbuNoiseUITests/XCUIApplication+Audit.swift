import XCTest

extension XCUIApplication {
    /// The accessibility audit of every flow: contrast comes from the tokens (checked by
    /// sync_tokens.py) and the figure is sized with @ScaledMetric, which the Dynamic Type audit
    /// does not recognize, as in the other apps. Every issue fails the test unless `isKnown` says so.
    ///
    /// On the slow CI runners the audit can run out of time before it reports anything
    /// (`Code=-56 "Audit failed to complete in time"`, SBU-399): then it starts again on the same
    /// screen, up to `attempts` times. A whole audit always runs; a timeout is never a pass.
    @MainActor
    func auditAccessibility(attempts: Int = 3, ignoring isKnown: @escaping (XCUIAccessibilityAuditIssue) -> Bool = { _ in false }) throws {
        for attempt in 1...attempts {
            do {
                try performAccessibilityAudit(for: XCUIAccessibilityAuditType.all.subtracting([.contrast, .dynamicType])) { issue in
                    if isKnown(issue) { return true }
                    XCTFail("\(issue.compactDescription): \(issue.element?.debugDescription ?? "no element")")
                    return true
                }
                return
            } catch let error as NSError where error.isAuditTimeout && attempt < attempts {
                XCTContext.runActivity(named: "Audit out of time, attempt \(attempt) of \(attempts): again") { _ in }
            }
        }
    }
}

private extension NSError {
    var isAuditTimeout: Bool {
        domain == "com.apple.xcode.xctest.accessibilityAudit" && code == -56
    }
}
