import XCTest

/// In December the home offers the year review: it opens on what you paid and what renews in January.
final class YearReviewFlowTests: XCTestCase {
    @MainActor
    func testOpenTheYearReview() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-FASTLANE_SNAPSHOT", "YES", "-SBU_TODAY", "2026-12-10", "-AppleLanguages", "(it)", "-AppleLocale", "it_IT"]
        app.launch()

        let row = app.buttons["yearReview"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["closeYearReview"].exists)
        let home = XCTAttachment(screenshot: app.screenshot())
        home.name = "home-dicembre"
        home.lifetime = .keepAlways
        add(home)

        row.tap()
        XCTAssertTrue(app.staticTexts["Si rinnovano a gennaio"].waitForExistence(timeout: 5)
            || app.staticTexts["SI RINNOVANO A GENNAIO"].exists)
        let review = XCTAttachment(screenshot: app.screenshot())
        review.name = "riepilogo"
        review.lifetime = .keepAlways
        add(review)
        try audit(app, "riepilogo")
        app.buttons["closeReviewSheet"].tap()
        XCTAssertTrue(row.waitForExistence(timeout: 5))
    }

    @MainActor
    private func audit(_ app: XCUIApplication, _ screen: String) throws {
        try app.performAccessibilityAudit(for: XCUIAccessibilityAuditType.all.subtracting([.contrast, .dynamicType])) { issue in
            XCTFail("\(screen): \(issue.compactDescription): \(issue.element.map { "\($0.elementType.rawValue) '\($0.label)' \($0.frame)" } ?? issue.detailedDescription)")
            return true
        }
    }
}
