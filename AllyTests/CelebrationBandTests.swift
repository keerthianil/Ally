import XCTest
@testable import Ally

/// The bands are a stance, not just a switch: every score gets a warm reaction,
/// and what changes is how loud it is.
final class CelebrationBandTests: XCTestCase {

    func testBoundaries() {
        XCTAssertEqual(CelebrationBand(score: 100), .amazing)
        XCTAssertEqual(CelebrationBand(score: 80), .amazing)
        XCTAssertEqual(CelebrationBand(score: 79), .good)
        XCTAssertEqual(CelebrationBand(score: 50), .good)
        XCTAssertEqual(CelebrationBand(score: 49), .foundation)
        XCTAssertEqual(CelebrationBand(score: 30), .foundation)
        XCTAssertEqual(CelebrationBand(score: 29), .beginning)
        XCTAssertEqual(CelebrationBand(score: 0), .beginning)
    }

    /// No band is allowed to be silent or scolding. A zero still gets copy that
    /// points forward, because accessibility guilt is what the app exists to
    /// remove.
    func testEveryBandIsWarmAndForwardLooking() {
        let punishing = ["fail", "failed", "poor", "bad", "wrong", "unacceptable", "should have"]
        for band in [CelebrationBand.amazing, .good, .foundation, .beginning] {
            XCTAssertFalse(band.headline.isEmpty)
            XCTAssertFalse(band.subtitle.isEmpty)
            let text = "\(band.headline) \(band.subtitle)".lowercased()
            for word in punishing {
                XCTAssertFalse(text.contains(word), "\(band) uses punishing language: \(word)")
            }
        }
    }

    func testBandsAreDistinct() {
        let bands: [CelebrationBand] = [.amazing, .good, .foundation, .beginning]
        XCTAssertEqual(Set(bands.map(\.headline)).count, 4, "Each band needs its own headline.")
        XCTAssertEqual(Set(bands.map(\.subtitle)).count, 4, "Each band needs its own copy.")
    }

    func testNoEmDashesInCelebrationCopy() {
        for band in [CelebrationBand.amazing, .good, .foundation, .beginning] {
            XCTAssertFalse(band.headline.contains("—"))
            XCTAssertFalse(band.subtitle.contains("—"))
        }
    }
}
