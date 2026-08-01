import XCTest
@testable import Ally

/// A curated corpus is only as good as the words it will answer to. These cover
/// the three ways a real question misses: the abbreviation nobody spells out, the
/// synonym the corpus doesn't use, and the typo.
final class AssistantVocabularyTests: XCTestCase {

    private func grounds(_ q: String) -> Bool {
        AssistantCorpus.groundingPassages(for: q) != nil
    }
    private func topIDs(_ q: String) -> [String] {
        AssistantCorpus.search(q, limit: 3).map(\.passage.id)
    }

    // MARK: Abbreviations

    /// "vo" is two characters, so before the abbreviation map it was discarded as
    /// noise and "How do I test with VO?" fell off the corpus entirely.
    func testAbbreviationsGround() {
        let cases = [
            "How do I test with VO?",
            "Does this work with a SR?",
            "What does AA mean for body text?",
            "Is this AAA?",
            "Do I need an aria label here?",
            "What about KB navigation?",
            "Is CVD a problem for these colours?",
            "What is COGA?",
            "Does DT break this layout?"
        ]
        for q in cases {
            XCTAssertTrue(grounds(q), "'\(q)' should ground. Terms: \(AssistantCorpus.tokenize(q))")
        }
    }

    /// Since the August 2026 content pass this lands on `voiceover-actions`,
    /// which is a better answer than the old one: it is the topic actually about
    /// testing with VoiceOver rather than about naming controls.
    func testVOReachesAVoiceOverTopic() {
        let ids = topIDs("How do I test with VO?")
        let acceptable = ["topic:voiceover-actions", "topic:labels", "topic:label-in-name", "topic:focus-order"]
        XCTAssertTrue(ids.contains(where: acceptable.contains),
                      "VoiceOver questions should reach a VoiceOver topic; got \(ids)")
    }

    func testAAReachesContrast() {
        XCTAssertTrue(topIDs("What ratio do I need for AA?").contains { $0.contains("contrast") || $0.contains("1.4.3") },
                      "AA should reach the contrast topic or criterion.")
    }

    // MARK: Synonyms — the words people actually use

    func testEverydayPhrasingsGround() {
        let cases = [
            "Is red and green enough to show errors?",
            "How big should a tap target be for someone with a tremor?",
            "My text gets truncated when someone zooms in",
            "Does this animation cause nausea?",
            "Is my microcopy too confusing?",
            "How do I write alt text for an icon?",
            "Do I need subtitles on this video?",
            "The spinner never announces anything",
            "Is a captcha a problem?",
            "What about people with dyslexia?",
            "Does tabbing work in a sensible order?",
            "The focus outline is invisible",
            "Why is 'read more' a bad link?",
            "Should a session time out?"
        ]
        for q in cases {
            XCTAssertTrue(grounds(q), "'\(q)' should ground. Terms: \(AssistantCorpus.tokenize(q))")
        }
    }

    func testBritishSpellingWorks() {
        XCTAssertTrue(grounds("What colour contrast do I need?"))
        XCTAssertTrue(grounds("Is this readable for colourblind users?"))
    }

    /// "a11y" and "accessibility" are deliberately *not* routed anywhere. They
    /// identify nothing inside a corpus where every entry is about accessibility,
    /// so "how do I check a11y on this screen" refuses and offers the nearest
    /// topic, which is the honest answer to a question that vague.
    func testVagueWholeSubjectQuestionsRefuse() {
        XCTAssertNil(AssistantCorpus.groundingPassages(for: "How do I check a11y on this screen?"))
        XCTAssertNil(AssistantCorpus.groundingPassages(for: "Is this accessible?"))
    }

    // MARK: Typos

    /// Without correction these hit the refusal path and get told Ally doesn't
    /// cover contrast, which is both wrong and maximally confusing.
    func testCommonTyposStillGround() {
        let cases = [
            "what contarst ratio do i need",
            "how do i use voiceovr",
            "how big should touch targests be",
            "whats a good readin level",
            "do i need captoins",
            "hedaings for structure",
            "keybord navigation"
        ]
        for q in cases {
            XCTAssertTrue(grounds(q), "'\(q)' should survive its typo. Terms: \(AssistantCorpus.tokenize(q))")
        }
    }

    func testCorrectionSnapsToVocabulary() {
        XCTAssertEqual(AssistantCorpus.correct("contarst"), "contrast")
        XCTAssertEqual(AssistantCorpus.correct("contrast"), "contrast", "A correct word must be left alone.")
    }

    /// The budget scales with length so short words can't drift into unrelated
    /// ones. This is the guard against correction making retrieval *worse*.
    func testShortWordsAreNotCorrected() {
        for w in ["cat", "car", "dog", "tax"] {
            XCTAssertEqual(AssistantCorpus.correct(w), w, "'\(w)' is too short to correct safely.")
        }
    }

    func testCriterionNumbersAreNeverCorrected() {
        for n in ["1.4.3", "2.5.8", "3.1.5"] {
            XCTAssertEqual(AssistantCorpus.correct(n), n)
        }
    }

    /// Correction must not become a back door around the refusal.
    func testTypoToleranceDoesNotBreakTheRefusal() {
        let offTopic = [
            "how do i set up stripe paymets",
            "kubernets deployment help",
            "wats the capitol of france",
            "write me a swiftui login screne"
        ]
        for q in offTopic {
            XCTAssertNil(AssistantCorpus.groundingPassages(for: q),
                         "'\(q)' is still off-topic. Terms: \(AssistantCorpus.tokenize(q))")
        }
    }
}
