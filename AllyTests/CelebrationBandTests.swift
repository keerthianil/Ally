import XCTest
@testable import Ally

/// The bands are a stance, not just a switch: every score gets a warm reaction,
/// and what changes is how loud it is.
final class CelebrationBandTests: XCTestCase {

    func testBoundaries() {
        XCTAssertEqual(CelebrationBand(score: 100), .strong)
        XCTAssertEqual(CelebrationBand(score: 80), .strong)
        XCTAssertEqual(CelebrationBand(score: 79), .building)
        XCTAssertEqual(CelebrationBand(score: 50), .building)
        XCTAssertEqual(CelebrationBand(score: 49), .starting)
        XCTAssertEqual(CelebrationBand(score: 0), .starting)
    }

    /// The band and the colour have to agree. They are read together on the
    /// celebration screen, the ring, and every project card, so a band that
    /// picked a different colour than `scoreColor` would be a visible bug.
    func testBandsAgreeWithTheScoreColours() {
        for score in [0, 20, 49, 50, 65, 79, 80, 95, 100] {
            let band = CelebrationBand(score: score)
            XCTAssertEqual(band.accent, ColorTokens.scoreColor(score),
                           "Band for \(score) does not use the score's own colour.")
            XCTAssertEqual(band.ink, ColorTokens.scoreInk(score))
            XCTAssertEqual(band.label, ColorTokens.scoreLabel(score))
        }
    }

    /// Three bands, three motion grammars. If two bands ever shared an accent or
    /// a palette head, the effects would stop being distinguishable.
    func testTheThreeBandsAreVisuallyDistinct() {
        let bands = CelebrationBand.allCases
        XCTAssertEqual(bands.count, 3)
        XCTAssertEqual(Set(bands.map { $0.representativeScore }).count, 3)
        for band in bands {
            XCTAssertFalse(band.palette.isEmpty, "\(band) has no palette to draw with.")
        }
    }

    /// No band is allowed to be silent or scolding. A zero still gets copy that
    /// points forward, because accessibility guilt is what the app exists to
    /// remove.
    func testEveryBandIsWarmAndForwardLooking() {
        let punishing = ["fail", "failed", "poor", "bad", "wrong", "unacceptable", "should have"]
        for band in CelebrationBand.allCases {
            XCTAssertFalse(band.headline.isEmpty)
            XCTAssertFalse(band.subtitle.isEmpty)
            let text = "\(band.headline) \(band.subtitle)".lowercased()
            for word in punishing {
                XCTAssertFalse(text.contains(word), "\(band) uses punishing language: \(word)")
            }
        }
    }

    func testBandsAreDistinct() {
        let bands = CelebrationBand.allCases
        XCTAssertEqual(Set(bands.map(\.headline)).count, bands.count, "Each band needs its own headline.")
        XCTAssertEqual(Set(bands.map(\.subtitle)).count, bands.count, "Each band needs its own copy.")
    }

    func testNoEmDashesInCelebrationCopy() {
        for band in CelebrationBand.allCases {
            XCTAssertFalse(band.headline.contains("—"))
            XCTAssertFalse(band.subtitle.contains("—"))
        }
    }
}
