import XCTest
@testable import Ally

/// The floating tab bar has two independent ways of getting out of the way, and
/// exactly one of them is allowed to happen while an assistive technology is on.
///
/// - `isCollapsed` is a response to scrolling. It shrinks the bar to a pill that
///   you tap to expand. Under VoiceOver, Switch Control, Voice Control, or Reduce
///   Motion it must never happen: the pill is expanded by a tap gesture on a
///   `.contain` container, which VoiceOver cannot activate, so a bar that
///   collapsed under VoiceOver would be a bar you could not get back.
/// - `isHidden` is a response to pushing a detail screen. That one is fine with
///   an assistive technology running, because the pushed screen has its own back
///   button and the bar returns on pop.
///
/// This was verified by reading the guard, which is not the same as verifying it.
final class TabBarVisibilityTests: XCTestCase {

    /// Enough scroll to collapse several times over.
    private func scrollDown(_ v: TabBarVisibility, locked: Bool, to offset: CGFloat = 900) {
        var y: CGFloat = 0
        while y <= offset {
            v.update(offset: y, contentHeight: 4000, viewportHeight: 800, locked: locked)
            y += 20
        }
    }

    func testScrollingDownCollapsesTheBar() {
        let v = TabBarVisibility()
        scrollDown(v, locked: false)
        XCTAssertTrue(v.isCollapsed, "A long scroll down should minimise the bar.")
    }

    /// The guard that matters.
    func testAssistiveTechNeverCollapsesTheBar() {
        let v = TabBarVisibility()
        scrollDown(v, locked: true)
        XCTAssertFalse(v.isCollapsed,
                       "The bar collapsed while an assistive technology was running. "
                       + "The collapsed pill is expanded by a tap gesture VoiceOver cannot reach.")
    }

    /// Turning an assistive technology on mid-scroll has to un-collapse it, not
    /// merely stop collapsing it further.
    func testTurningAssistiveTechOnRestoresACollapsedBar() {
        let v = TabBarVisibility()
        scrollDown(v, locked: false)
        XCTAssertTrue(v.isCollapsed)
        v.update(offset: 920, contentHeight: 4000, viewportHeight: 800, locked: true)
        XCTAssertFalse(v.isCollapsed, "Enabling VoiceOver mid-scroll must bring the bar back.")
    }

    func testScrollingBackUpExpandsTheBar() {
        let v = TabBarVisibility()
        scrollDown(v, locked: false)
        XCTAssertTrue(v.isCollapsed)
        v.update(offset: 860, contentHeight: 4000, viewportHeight: 800, locked: false)
        XCTAssertFalse(v.isCollapsed, "Scrolling up should expand immediately.")
    }

    /// Near the top nothing is being obscured yet, so there is nothing to get out
    /// of the way of.
    func testTheBarStaysExpandedNearTheTop() {
        let v = TabBarVisibility()
        scrollDown(v, locked: false, to: 100)
        XCTAssertFalse(v.isCollapsed)
    }

    /// A screen that barely scrolls has no reason to minimise anything.
    func testShortContentNeverCollapses() {
        let v = TabBarVisibility()
        var y: CGFloat = 0
        while y <= 300 {
            v.update(offset: y, contentHeight: 900, viewportHeight: 800, locked: false)
            y += 20
        }
        XCTAssertFalse(v.isCollapsed)
    }

    // MARK: Hidden on push

    func testHidingIsIndependentOfAssistiveTech() {
        let v = TabBarVisibility()
        v.setHidden(true)
        XCTAssertTrue(v.isHidden, "Pushing a detail screen hides the bar regardless.")
        v.setHidden(false)
        XCTAssertFalse(v.isHidden)
    }

    /// Popping back must restore a whole bar, not the collapsed pill it happened
    /// to be in several screens ago.
    func testPoppingRestoresTheBarExpanded() {
        let v = TabBarVisibility()
        scrollDown(v, locked: false)
        XCTAssertTrue(v.isCollapsed)
        v.setHidden(true)
        v.setHidden(false)
        XCTAssertFalse(v.isHidden)
        XCTAssertFalse(v.isCollapsed, "The bar came back still collapsed, which reads as a glitch.")
    }

    func testResetClearsBothStates() {
        let v = TabBarVisibility()
        scrollDown(v, locked: false)
        v.setHidden(true)
        v.reset()
        XCTAssertFalse(v.isCollapsed)
        XCTAssertFalse(v.isHidden)
    }

    /// Rubber-band overscroll at either end produces large fake deltas.
    func testOverscrollIsIgnored() {
        let v = TabBarVisibility()
        v.update(offset: -300, contentHeight: 4000, viewportHeight: 800, locked: false)
        XCTAssertFalse(v.isCollapsed)
        v.update(offset: 5000, contentHeight: 4000, viewportHeight: 800, locked: false)
        XCTAssertFalse(v.isCollapsed)
    }
}
