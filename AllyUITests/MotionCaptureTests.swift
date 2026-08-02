import XCTest

/// Frame grabs of the two things about Ally that a still cannot show: a card
/// turning over, and a score arriving.
///
/// Not a pass/fail test. It drives a real interaction and grabs `XCUIScreen`
/// frames as fast as the harness allows, each one attached under a zero-padded
/// name so the host can sort them and assemble a GIF. `XCUIScreen.main.screenshot()`
/// is used rather than `app.screenshot()` because it skips the accessibility
/// snapshot and is roughly three times faster, which is the difference between a
/// legible animation and a slideshow.
///
/// The alternative was `simctl io recordVideo`, which needs ffmpeg to trim the
/// app-launch head off the front. Grabbing frames from inside the interaction
/// means the clip starts exactly where it should.
final class MotionCaptureTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    /// The flash card turning: front, flip, back, next card, flip again.
    @MainActor
    func testCaptureCardFlip() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTest", "-openTool", "wcag"]
        app.launch()
        sleep(2)

        let flip = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "Show the")).firstMatch
        let next = app.buttons["Next"].firstMatch
        guard flip.waitForExistence(timeout: 5), next.exists else {
            XCTFail("The deck controls are missing; nothing to record.")
            return
        }

        // Hold on the front for a beat, flip, hold, advance, flip. The taps are
        // fired between grabs rather than on a timer, so the clip always shows
        // the whole of each transition.
        var frame = 0
        func grab(_ count: Int) {
            for _ in 0..<count {
                let shot = XCUIScreen.main.screenshot()
                let attachment = XCTAttachment(screenshot: shot)
                attachment.name = String(format: "flip-%03d", frame)
                attachment.lifetime = .keepAlways
                add(attachment)
                frame += 1
            }
        }

        grab(6)
        flip.tap();  grab(14)
        grab(6)
        next.tap();  grab(12)
        flip.tap();  grab(14)
        grab(6)
    }

    /// The celebration, one clip per band, so the three motion grammars can be
    /// compared side by side rather than described.
    @MainActor
    func testCaptureCelebrationMotion() {
        for band in ["strong", "building", "starting"] {
            let app = XCUIApplication()
            app.launchArguments = ["-uiTest", "-resetStore", "-seedDemo",
                                   "-seedBand", band, "-openCelebration"]
            app.launch()
            // The ring sweep runs for about 1.1s and the effect lands just after
            // it, so the grab starts immediately and covers the whole arrival.
            for i in 0..<34 {
                let shot = XCUIScreen.main.screenshot()
                let attachment = XCTAttachment(screenshot: shot)
                attachment.name = String(format: "band-%@-%03d", band, i)
                attachment.lifetime = .keepAlways
                add(attachment)
            }
        }
    }
}
