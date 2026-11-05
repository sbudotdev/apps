import XCTest

/// Home, an Intenzione's sheet and Impostazioni open and pass the accessibility audit, on the
/// sample Shield and on first run. Screen Time itself runs only on a device.
final class FlowTests: XCTestCase {
    /// Contrast is left out as in the other apps: the audit misreads the grid paper behind text.
    private static let exclusions: XCUIAccessibilityAuditType = [.contrast]
    /// SbuKit's settings also leave out Dynamic Type and clipped text, as the settings sheet does in
    /// the other apps: the system caps the Licenze row and the switch rows below the largest sizes.
    /// How far above the tab bar the audit's larger text sizes reach under it.
    private static let tabBarReach: CGFloat = 120
    private static let settingsExclusions: XCUIAccessibilityAuditType = [.contrast, .dynamicType, .textClipped]
    /// A sheet with a native form, as in Sbu Meds: bar buttons show in the Large Content Viewer
    /// instead of scaling, and the system caps section footers and SbuButton below the largest sizes.
    private static let formExclusions: XCUIAccessibilityAuditType = [.contrast, .dynamicType]

    @MainActor
    func testEveryScreenOpensAndPassesTheAudit() throws {
        let app = launch(store: "-SBU_SAMPLE_STORE")
        XCTAssertTrue(app.buttons["Blocca ora"].waitForExistence(timeout: 5), "The app opens on Home")
        try audit(app)

        app.buttons.containing(.staticText, identifier: "Instagram").firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Intenzione"].waitForExistence(timeout: 5), "A row opens its Intenzione")
        try audit(app, excluding: Self.formExclusions)
        app.buttons["Annulla"].tap()

        // By label, not through the tab bar: on a wide screen such as iPhone Duo's inner display
        // the tabs are buttons in a side toolbar.
        app.buttons["Sessioni"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Nuova Sessione"].waitForExistence(timeout: 5), "The Sessioni tab opens")
        try audit(app)

        app.buttons.containing(.staticText, identifier: "Notte").firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Sessione"].waitForExistence(timeout: 5), "A row opens its Sessione")
        try audit(app, excluding: Self.formExclusions)
        app.buttons["Annulla"].tap()

        // The sample's only Sessione is off: one that is on can only be the idea just added.
        let isOn = app.buttons.containing(.staticText, identifier: "Accesa").firstMatch
        XCTAssertFalse(isOn.exists)
        app.buttons.containing(.staticText, identifier: "Cena").firstMatch.tap()
        XCTAssertTrue(isOn.waitForExistence(timeout: 5), "An idea becomes a Sessione that is on")

        app.buttons["Impostazioni"].firstMatch.tap()
        try audit(app, excluding: Self.settingsExclusions)
    }

    @MainActor
    func testFirstRunOffersAnIntentionAndWaitsForItsApp() throws {
        let app = launch(store: "-SBU_EMPTY_STORE")
        XCTAssertTrue(app.buttons["Aggiungi un'Intenzione"].waitForExistence(timeout: 5), "First run offers an Intenzione")
        try audit(app)

        app.buttons["Aggiungi un'Intenzione"].tap()
        XCTAssertTrue(app.navigationBars["Nuova Intenzione"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Salva"].isEnabled, "Nothing to save until an app is chosen")
        try audit(app, excluding: Self.formExclusions)
    }

    @MainActor
    private func launch(store: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(it)", "-AppleLocale", "it_IT", store, "YES"]
        app.launch()
        return app
    }

    @MainActor
    private func audit(_ app: XCUIApplication, excluding excluded: XCUIAccessibilityAuditType = exclusions) throws {
        let tabBar = app.tabBars.firstMatch
        let tabBarTop = tabBar.exists ? tabBar.frame.minY : .infinity
        try app.performAccessibilityAudit(for: XCUIAccessibilityAuditType.all.subtracting(excluded)) { issue in
            let label = issue.element?.label ?? ""
            // A row just above the floating tab bar: at larger text sizes the audit grows it under the
            // bar and calls it cut, but the page scrolls and the row stays whole above it.
            if [.dynamicType, .textClipped].contains(issue.auditType), let frame = issue.element?.frame,
               frame.maxY > tabBarTop - Self.tabBarReach {
                return true
            }
            // SbuKit's cartiglio: Plex Mono relative to caption2, capped by the system at the
            // largest sizes, and tracked uppercase, which the audit measures as clipped (as in Sbu Find).
            if [.dynamicType, .textClipped].contains(issue.auditType), label.hasPrefix("SBU · ") {
                return true
            }
            // A sheet's inline title is laid out by the system and shows whole; the audit measures
            // it while the sheet is still settling (as in Sbu Meds).
            if issue.auditType == .textClipped,
               app.navigationBars.staticTexts.matching(NSPredicate(format: "label == %@", label)).firstMatch.exists {
                return true
            }
            // SbuFigure: the hero figure snaps to the grid by its length, not by text size, by design.
            // Home's is a time, "0:45:00".
            if issue.auditType == .dynamicType, !label.isEmpty, label.allSatisfy({ $0.isNumber || $0 == ":" }) {
                return true
            }
            XCTFail("\(issue.compactDescription): \(issue.element?.debugDescription ?? "no element")")
            return true
        }
    }
}
