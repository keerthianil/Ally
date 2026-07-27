import XCTest

/// Automated accessibility sweep. Ally teaches accessibility, so it holds itself
/// to its own bar: every tab root and the deeper screens are run through Apple's
/// `performAccessibilityAudit`, which flags unlabeled controls, sub-44pt hit
/// regions, and missing descriptions the way VoiceOver would encounter them.
///
/// We audit the meaningful categories and deliberately skip `.contrast`,
/// `.dynamicType`, and `.textClipped`: those fire on the intentionally
/// low-contrast decorative background and the oversized display numerals, which
/// are validated separately (the app's own Contrast Checker covers token pairs).
final class AllyAccessibilityAuditTests: XCTestCase {

    private let auditTypes: XCUIAccessibilityAuditType = [
        .elementDetection, .hitRegion, .sufficientElementDescription, .trait
    ]

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    @MainActor
    func testLearnTabAccessibility() throws {
        let app = XCUIApplication()
        app.launch()
        try auditCurrentScreen(app) // Learn is the default tab

        // Open the first topic card and audit the detail screen.
        let firstCard = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Color Contrast")).firstMatch
        if firstCard.waitForExistence(timeout: 5) {
            firstCard.tap()
            try auditCurrentScreen(app)
        }
    }

    @MainActor
    func testCheckTabAccessibility() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-seedDemo"]
        app.launch()
        app.buttons["Check"].firstMatch.tap()
        try auditCurrentScreen(app)
    }

    @MainActor
    func testToolkitAccessibility() throws {
        let app = XCUIApplication()
        app.launch()
        app.buttons["Toolkit"].firstMatch.tap()
        try auditCurrentScreen(app)

        // Contrast Checker — the most control-dense tool.
        let contrast = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Contrast Checker")).firstMatch
        if contrast.waitForExistence(timeout: 5) {
            contrast.tap()
            try auditCurrentScreen(app)
        }
    }

    // MARK: Helper

    @MainActor
    private func auditCurrentScreen(_ app: XCUIApplication) throws {
        try app.performAccessibilityAudit(for: auditTypes) { issue in
            print("♿️ AUDIT ISSUE [\(issue.auditType)] element=<\(issue.element?.debugDescription ?? "nil")> :: \(issue.detailedDescription)")
            return false // keep failing so we still see the assertion, but log details
        }
    }
}
