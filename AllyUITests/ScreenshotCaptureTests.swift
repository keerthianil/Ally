import XCTest

/// Portfolio screenshot generator (not a pass/fail test). Drives the app to each
/// key screen and captures a full-resolution `app.screenshot()` as a named,
/// keep-always attachment. Run the whole class once per appearance (the host
/// script toggles `simctl ui … appearance`) and extract the attachments with
/// `xcresulttool`.
///
/// Screens reachable by launch flag are captured directly; the few that need
/// navigation reuse the app's real accessibility labels.
final class ScreenshotCaptureTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    // MARK: Flag-reachable screens (one relaunch each)

    /// Split in two on purpose. The simulator gives up after roughly fifteen
    /// consecutive `app.launch()` calls in one session (`Mach error -308`), which
    /// fails the whole class partway through even when every test passes on its
    /// own. Two shorter tests stay under it.
    @MainActor
    func testCaptureFlagScreensA() {
        capture([
            (["-uiTest"],                                "learn-home",       1),
            (["-uiTest", "-showOnboarding"],             "onboarding",       2),
            (["-uiTest", "-openAssistant"],              "assistant",        2),
            (["-uiTest", "-resetStore", "-seedDemo", "-tabCheck"], "check-home", 2),
            (["-uiTest", "-seedDemo", "-openResult"],    "check-result",     3),
            (["-uiTest", "-tabToolkit"],                 "toolkit-home",     1),
            (["-uiTest", "-openTool", "wcag"],           "tool-wcag",        1)
        ])
    }

    @MainActor
    func testCaptureFlagScreensB() {
        capture([
            (["-uiTest", "-openTool", "contrast"],       "tool-contrast",    1),
            (["-uiTest", "-openTool", "cvd"],            "tool-cvd",         1),
            (["-uiTest", "-openTool", "readability"],    "tool-readability", 1),
            (["-uiTest", "-openTool", "touchTarget"],    "tool-touchtarget", 1)
        ])
    }

    @MainActor
    private func capture(_ shots: [(args: [String], name: String, settle: UInt32)]) {
        for shot in shots {
            let app = XCUIApplication()
            app.launchArguments = shot.args
            app.launch()
            sleep(shot.settle)
            snap(app, shot.name)
        }
    }

    // MARK: Learn — deeper screens
    //
    // Both selectors here went stale and neither failed, which is the worst way
    // for a screenshot test to break: it hunted for a "Color Contrast" card that
    // browse no longer shows and a "Vision topics" filter chip that was deleted,
    // found neither, and passed. Learn now opens on four lens cards, so the two
    // routes in are the search field and a lens.

    @MainActor
    func testCaptureLearnDeep() {
        // Search, which is what swaps Learn into the masonry layout.
        var app = XCUIApplication()
        app.launchArguments = ["-uiTest"]
        app.launch()
        let search = app.textFields["Search topics"].firstMatch
        if search.waitForExistence(timeout: 5) {
            search.tap()
            search.typeText("contrast")
            sleep(1)
            snap(app, "learn-search")

            let card = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Color Contrast")).firstMatch
            if card.waitForExistence(timeout: 3) {
                card.tap()
                sleep(1)
                snap(app, "learn-topic-detail")
            }
        }

        // A whole lens, which is the browse route.
        app = XCUIApplication()
        app.launchArguments = ["-uiTest"]
        app.launch()
        let lens = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Vision.")).firstMatch
        if lens.waitForExistence(timeout: 5) {
            lens.tap()
            sleep(1)
            snap(app, "learn-category")
        }
    }

    // MARK: Check — the three celebration bands
    //
    // Kept in its own test rather than folded into the flag list: the effect a
    // score gets is chosen by the score, so this needs one relaunch per band, and
    // a single test doing thirteen consecutive launches is what makes the
    // simulator give up halfway through.

    @MainActor
    func testCaptureCelebrationBands() {
        for band in ["strong", "building", "starting"] {
            let app = XCUIApplication()
            app.launchArguments = ["-uiTest", "-seedDemo", "-seedBand", band, "-openCelebration"]
            app.launch()
            sleep(2) // mid-burst for strong, settled for the other two
            snap(app, "check-celebration-\(band)")
        }
    }

    // MARK: Toolkit — the flash card, both faces

    @MainActor
    func testCaptureWCAGCardBack() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTest", "-openTool", "wcag"]
        app.launch()
        let flip = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Show the fix")).firstMatch
        if flip.waitForExistence(timeout: 5) {
            flip.tap()
            sleep(1)
            snap(app, "tool-wcag-back")
        }
    }

    // MARK: Check — new project + first question

    @MainActor
    func testCaptureCheckDeep() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTest", "-seedDemo", "-tabCheck"]
        app.launch()

        // Exact label avoids matching the "Check" tab-bar button.
        let newCheck = app.buttons["New check"].firstMatch
        guard newCheck.waitForExistence(timeout: 5) else { return }
        newCheck.tap()
        sleep(1)

        // The create-project sheet.
        let nameField = app.textFields.firstMatch
        if nameField.waitForExistence(timeout: 3) {
            nameField.tap()
            nameField.typeText("Checkout redesign")
            snap(app, "check-newproject")

            // Start → first checkpoint question.
            let start = app.buttons["Start"].firstMatch
            if start.waitForExistence(timeout: 3) {
                start.tap()
                sleep(1)
                snap(app, "check-flow-question")
            }
        }
    }

    // MARK: Helper

    @MainActor
    private func snap(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
