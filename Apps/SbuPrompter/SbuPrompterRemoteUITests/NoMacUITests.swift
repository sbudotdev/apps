import XCTest

/// The screen App Review sees without a Mac: it must pass the accessibility audit on its own.
final class NoMacUITests: XCTestCase {
    @MainActor
    func testTheEmptyScreenPassesTheAccessibilityAudit() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(it)", "-AppleLocale", "it_IT"]
        // No network: a Mac running Sbu Prompter nearby would otherwise replace the empty screen.
        app.launchEnvironment["SBU_PROMPTER_OFFLINE"] = "1"
        app.launch()

        XCTAssertTrue(app.staticTexts["Telecomando"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Apri Sbu Prompter sul Mac'")).firstMatch.exists)
        try app.performAccessibilityAudit(for: [.contrast, .dynamicType, .elementDetection, .hitRegion,
                                                .sufficientElementDescription]) { issue in
            // SbuKit's uppercase cartiglio (SbuScreenTitle) is shared by every app, so its type size and its
            // muted colour are not this app's to change (same exception as RemoteWithMacUITests).
            if [.dynamicType, .contrast].contains(issue.auditType), let label = issue.element?.label, label == label.uppercased() {
                return true
            }
            XCTFail("\(issue.compactDescription): \(issue.element?.debugDescription ?? "no element")")
            return true
        }
    }
}
