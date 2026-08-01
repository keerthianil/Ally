import XCTest
@testable import Ally

/// Onboarding shows once, and must never get in the way of a test or a
/// screenshot that was aimed at a specific screen.
final class OnboardingGateTests: XCTestCase {

    func testShowsOnFirstRunOnly() {
        // No launch arguments are present in a unit-test process, so this is the
        // plain first-run and returning-user behaviour.
        XCTAssertTrue(OnboardingGate.shouldShow(hasSeen: false))
        XCTAssertFalse(OnboardingGate.shouldShow(hasSeen: true))
    }

    func testEveryPageCarriesItsContent() {
        let pages = OnboardingView.Page.all
        XCTAssertEqual(pages.count, 4)
        for p in pages {
            XCTAssertFalse(p.title.isEmpty)
            XCTAssertFalse(p.body.isEmpty)
            XCTAssertFalse(p.pin.isEmpty, "Every page needs the one claim it wants remembered.")
        }
    }

    /// The framing is the reason onboarding exists, so the two corrections it has
    /// to land are asserted rather than left to drift out of the copy.
    func testFramingClaimsArePresent() {
        let all = OnboardingView.Page.all.map { "\($0.title) \($0.body) \($0.pin)" }.joined(separator: " ")
        XCTAssertTrue(all.contains("dictionary, not a course"))
        XCTAssertTrue(all.contains("self-assessment, not an audit"))
        XCTAssertTrue(all.lowercased().contains("not sure"), "\"Not sure\" not counting is the ethics call worth stating.")
        XCTAssertTrue(all.contains("on your iPhone"), "On-device has to be said, not implied.")
    }

    /// No em dashes in onboarding copy either.
    func testCopyHasNoEmDashes() {
        for p in OnboardingView.Page.all {
            for field in [p.eyebrow, p.title, p.body, p.pin] {
                XCTAssertFalse(field.contains("—"), "Em dash in: \(field)")
            }
        }
    }
}
