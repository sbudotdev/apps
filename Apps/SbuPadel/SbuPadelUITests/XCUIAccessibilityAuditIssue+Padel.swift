import XCTest

extension XCUIAccessibilityAuditIssue {
    /// SbuScreenTitle's cartiglio, "SBU · PADEL": the audit reads `Font.sbuCartiglio`, which SbuKit
    /// scales with `.caption2`, as clipped and only partly following the text size. Face and size come from SbuKit.
    var isCartiglio: Bool {
        guard auditType == .textClipped || auditType == .dynamicType, let label = element?.label else { return false }
        return label.hasPrefix("SBU · ")
    }

    /// The game call, 144 pt: fixed on purpose, it steps down to fit its half instead of growing
    /// with the text size, so the audit reports it as not following it.
    var isGameCall: Bool {
        guard auditType == .dynamicType, let element else { return false }
        return element.label.hasPrefix("Punto a") || element.label.hasPrefix("Point to") || element.frame.height >= 120
    }
}
