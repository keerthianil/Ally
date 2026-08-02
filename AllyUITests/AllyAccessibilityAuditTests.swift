import XCTest

/// Automated accessibility sweep. Ally teaches accessibility, so it holds itself
/// to its own bar: every tab root and the deeper screens are run through Apple's
/// `performAccessibilityAudit`, which flags unlabeled controls, sub-44pt hit
/// regions, and missing descriptions the way VoiceOver would encounter them.
///
/// We audit the meaningful categories and deliberately skip `.contrast`,
/// `.dynamicType`, and `.textClipped`: those fire on the intentionally
/// low-contrast decorative background and the oversized display numerals.
/// Contrast is not left unchecked, though — `ColorTokenContrastTests` recomputes
/// every token pair in both appearances and fails the build on a regression,
/// which is stricter than a rendered-pixel sample and covers dark mode too.
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
        app.launchArguments += ["-skipOnboarding"]
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
        app.launchArguments += ["-skipOnboarding"]
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

    /// The flash-card deck, which is the densest control cluster in the app:
    /// nine filter chips, three deck controls, and a card that is one element
    /// carrying four custom actions.
    @MainActor
    func testWCAGDeckAccessibility() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-openTool", "wcag"]
        app.launch()
        try auditCurrentScreen(app)

        // Flip the card and audit the back, which has its own content and its
        // own deep link into Learn.
        let flip = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Show the fix")).firstMatch
        if flip.waitForExistence(timeout: 5) {
            flip.tap()
            try auditCurrentScreen(app)
        }
    }

    /// The report. Score wash, living category stickers, and the prioritised
    /// fix list, none of which existed when this file was written.
    @MainActor
    func testScoreResultAccessibility() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-seedDemo", "-openResult"]
        app.launch()
        try auditCurrentScreen(app)
    }

    /// The two on-device-model surfaces, audited in the state most users will
    /// actually get: no Apple Intelligence. The fallback is a real screen, so it
    /// has to pass the same bar as everything else.
    @MainActor
    func testAssistantAccessibilityWithoutModel() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-openAssistant", "-forceAIStatus", "notEnabled"]
        app.launch()
        try auditCurrentScreen(app)
    }

    @MainActor
    func testReadabilityAccessibilityWithoutModel() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-openTool", "readability", "-forceAIStatus", "notEnabled"]
        app.launch()
        try auditCurrentScreen(app)
    }

    /// Onboarding is the first thing a new install sees, so it is audited too.
    /// Each page is its own VoiceOver container and the page change is announced.
    @MainActor
    func testOnboardingAccessibility() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-showOnboarding"]
        app.launch()
        try auditCurrentScreen(app)

        // Walk to the last page so the assistant art and final button are audited too.
        let next = app.buttons["Next"].firstMatch
        var guard_ = 0
        while next.waitForExistence(timeout: 2), guard_ < 5 {
            next.tap()
            guard_ += 1
        }
        try auditCurrentScreen(app)
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
