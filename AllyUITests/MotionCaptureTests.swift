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

    /// The four lens marks idling on Learn home. This is the clearest single view
    /// of the living-art vocabulary: the eye blinks and tracks, the target
    /// ripples, the thought nodes orbit, the route marker travels, all off one
    /// shared clock so the page breathes together.
    @MainActor
    func testCaptureLivingArt() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTest"]
        app.launch()
        sleep(1) // let the entrance settle so the clip is pure idle
        for i in 0..<40 {
            let shot = XCUIScreen.main.screenshot()
            let a = XCTAttachment(screenshot: shot)
            a.name = String(format: "living-%03d", i)
            a.lifetime = .keepAlways
            add(a)
        }
    }

    /// The score ring sweep-filling and the numeral counting up, on the report.
    /// The signature animation, isolated from the celebration effects so it can
    /// be read on its own.
    @MainActor
    func testCaptureRingSweep() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTest", "-resetStore", "-seedDemo", "-openResult"]
        app.launch()
        // Grab from the first frame: the sweep is over in about 1.1s, so speed
        // matters more here than anywhere else.
        for i in 0..<26 {
            let shot = XCUIScreen.main.screenshot()
            let a = XCTAttachment(screenshot: shot)
            a.name = String(format: "ring-%03d", i)
            a.lifetime = .keepAlways
            add(a)
        }
    }

    /// The before/after slider, wiped as a stop-motion. A real drag is a blocking
    /// call that a UI test cannot grab mid-flight, so instead the accessible
    /// slider is adjusted to a sequence of positions and a frame is grabbed at
    /// each: assembled, it reads as one smooth wipe, and it is the marquee Learn
    /// interaction.
    @MainActor
    func testCaptureBeforeAfterWipe() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTest"]
        app.launch()

        // Browse now opens on the four lens cards, so the topic is reached by
        // searching, which is also the route that swaps Learn into the masonry.
        let search = app.textFields["Search topics"].firstMatch
        guard search.waitForExistence(timeout: 5) else { XCTFail("Search field not found"); return }
        search.tap()
        search.typeText("contrast")

        let card = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Color Contrast")).firstMatch
        guard card.waitForExistence(timeout: 5) else { XCTFail("Color Contrast topic not found"); return }
        card.tap()

        let slider = app.sliders["Before and after comparison"].firstMatch
        guard slider.waitForExistence(timeout: 5) else { XCTFail("Before/after slider not found"); return }
        // The demo sits low on the topic detail, below the failure card and the
        // fix list, so bring it up into clear view before wiping it.
        app.swipeUp()
        app.swipeUp()
        _ = slider.waitForExistence(timeout: 2)

        var frame = 0
        func grab() {
            let shot = XCUIScreen.main.screenshot()
            let a = XCTAttachment(screenshot: shot)
            a.name = String(format: "wipe-%03d", frame); a.lifetime = .keepAlways
            add(a); frame += 1
        }

        // Coordinate drags rather than adjust(toNormalizedSliderPosition:): the
        // accessible representation refuses to synthesize an adjust event here,
        // but a plain press-and-drag on the same element's coordinate space moves
        // the bound fraction just as well. Sweep left, then back right, so the
        // loop returns to where it started.
        let mid = slider.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        func dragTo(_ dx: CGFloat) {
            let target = slider.coordinate(withNormalizedOffset: CGVector(dx: dx, dy: 0.5))
            mid.press(forDuration: 0.05, thenDragTo: target)
        }
        grab()
        for dx in [CGFloat(0.35), 0.2, 0.08, 0.25, 0.5, 0.7, 0.9, 0.65, 0.5] {
            dragTo(dx); grab(); grab()
        }
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
