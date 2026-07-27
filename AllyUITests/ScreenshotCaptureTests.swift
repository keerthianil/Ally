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

    @MainActor
    func testCaptureFlagScreens() {
        let shots: [(args: [String], name: String, settle: UInt32)] = [
            (["-uiTest"],                              "learn-home",        1),
            (["-uiTest", "-seedDemo", "-tabCheck"],    "check-home",        1),
            (["-uiTest", "-seedDemo", "-openCelebration"], "check-celebration", 3),
            (["-uiTest", "-seedDemo", "-openResult"],  "check-result",      3),
            (["-uiTest", "-tabToolkit"],               "toolkit-home",      1),
            (["-uiTest", "-openTool", "contrast"],     "tool-contrast",     1),
            (["-uiTest", "-openTool", "cvd"],          "tool-cvd",          1),
            (["-uiTest", "-openTool", "readability"],  "tool-readability",  1),
            (["-uiTest", "-openTool", "touchTarget"],  "tool-touchtarget",  1),
            (["-uiTest", "-openTool", "wcag"],         "tool-wcag",         1)
        ]
        for shot in shots {
            let app = XCUIApplication()
            app.launchArguments = shot.args
            app.launch()
            sleep(shot.settle)
            snap(app, shot.name)
        }
    }

    // MARK: Learn — deeper screens

    @MainActor
    func testCaptureLearnDeep() {
        // Topic detail (with the before/after demo).
        var app = XCUIApplication()
        app.launchArguments = ["-uiTest"]
        app.launch()
        let card = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Color Contrast")).firstMatch
        if card.waitForExistence(timeout: 5) {
            card.tap()
            sleep(1)
            snap(app, "learn-topic-detail")
        }

        // Category-filtered grid.
        app = XCUIApplication()
        app.launchArguments = ["-uiTest"]
        app.launch()
        let chip = app.buttons["Vision topics"].firstMatch
        if chip.waitForExistence(timeout: 5) {
            chip.tap()
            sleep(1)
            snap(app, "learn-filtered")
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
