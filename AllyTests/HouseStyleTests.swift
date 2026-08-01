import XCTest
@testable import Ally

/// The model is told the voice rules, which gets most of the way. This is the
/// part that doesn't rely on it complying.
final class HouseStyleTests: XCTestCase {

    // MARK: Dashes

    func testEmDashesAreRemoved() {
        let cases: [(String, String)] = [
            ("Use 4.5 to 1 — anything less is hard to read.",
             "Use 4.5 to 1, anything less is hard to read."),
            ("Contrast matters — Body text needs 4.5 to 1.",
             "Contrast matters. Body text needs 4.5 to 1."),
            ("Targets should be 44pt—that is Apple's minimum.",
             "Targets should be 44pt, that is Apple's minimum."),
            ("Three things matter: contrast — size — and labels.",
             "Three things matter: contrast, size, and labels.")
        ]
        for (input, expected) in cases {
            XCTAssertEqual(HouseStyle.stripDashes(input), expected)
        }
    }

    func testNoDashSurvivesAFullClean() {
        let messy = "Great question! Based on the passages — body text needs 4.5:1 — and it's important to note that large text is different."
        let out = HouseStyle.clean(messy)
        XCTAssertFalse(out.contains("—"), "An em dash survived: \(out)")
        XCTAssertFalse(out.contains("―"), "A horizontal bar survived: \(out)")
    }

    /// An en dash between digits is a numeric range, not punctuation.
    func testNumericRangesKeepTheirEnDash() {
        XCTAssertEqual(HouseStyle.stripDashes("Scores of 60–79 are amber."),
                       "Scores of 60–79 are amber.")
        XCTAssertEqual(HouseStyle.stripDashes("A ratio of 4.5–7 passes AA."),
                       "A ratio of 4.5–7 passes AA.")
    }

    func testEnDashAsPunctuationIsRemoved() {
        XCTAssertEqual(HouseStyle.stripDashes("Contrast is the issue – fix it first."),
                       "Contrast is the issue, fix it first.")
    }

    // MARK: Preamble

    func testPreambleIsStripped() {
        let cases = [
            "Great question! Body text needs 4.5 to 1.",
            "Based on the passages, body text needs 4.5 to 1.",
            "According to the context, body text needs 4.5 to 1.",
            "Sure, body text needs 4.5 to 1.",
            "In summary, body text needs 4.5 to 1."
        ]
        for c in cases {
            let out = HouseStyle.stripPreamble(c)
            XCTAssertTrue(out.hasPrefix("Body text"), "Preamble survived in: \(out)")
        }
    }

    func testStackedPreamblesAreStripped() {
        let out = HouseStyle.stripPreamble("Great question! Based on the passages, body text needs 4.5 to 1.")
        XCTAssertTrue(out.hasPrefix("Body text"), "Got: \(out)")
    }

    func testCleanAnswerIsLeftAlone() {
        let good = "Body text needs a contrast ratio of at least 4.5 to 1. Large text can go down to 3 to 1."
        XCTAssertEqual(HouseStyle.clean(good), good)
    }

    // MARK: Filler

    func testFillerIsReplaced() {
        XCTAssertEqual(HouseStyle.stripFiller("Additionally, check the labels."), "Also, check the labels.")
        XCTAssertEqual(HouseStyle.stripFiller("Ensure that every control has a name."),
                       "Make sure every control has a name.")
        XCTAssertFalse(HouseStyle.clean("It's important to note that contrast matters.").contains("important to note"))
        XCTAssertFalse(HouseStyle.clean("Utilize the label property.").lowercased().contains("utilize"))
    }

    /// The rewriter exists to make copy plainer, so its own output has to clear
    /// the bar. A rewrite full of "Furthermore" would be self-defeating.
    func testCleanedOutputReadsEasierThanModelDefault() {
        let modelish = "Additionally, it's important to note that you should utilize the label property in order to ensure that assistive technology can identify the control."
        let cleaned = HouseStyle.clean(modelish)
        let before = ReadabilityStats.analyze(modelish).gradeLevel
        let after = ReadabilityStats.analyze(cleaned).gradeLevel
        XCTAssertLessThan(after, before, "Cleaning should not make text harder. \(before) -> \(after)")
    }

    // MARK: Whitespace

    func testWhitespaceIsTidied() {
        XCTAssertEqual(HouseStyle.clean("Too   many    spaces here."), "Too many spaces here.")
        XCTAssertEqual(HouseStyle.clean("  Leading and trailing.  "), "Leading and trailing.")
    }

    func testEmptyInputSurvives() {
        XCTAssertEqual(HouseStyle.clean(""), "")
        XCTAssertEqual(HouseStyle.clean("   "), "")
    }

    // MARK: The rules the model is given

    func testVoiceRulesNameTheDashBan() {
        XCTAssertTrue(HouseStyle.voiceRules.lowercased().contains("em dash"),
                      "The model has to be told, not just corrected afterwards.")
    }
}
