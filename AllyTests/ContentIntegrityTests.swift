import XCTest
@testable import Ally

/// The Learn topics and the WCAG reference are two hand-maintained tables that
/// point at each other by loose string id. Nothing in the compiler checks that,
/// and four links were quietly broken before this file existed: Reflow pointed
/// at the Dynamic Type topic, Non-text Contrast pointed at Color Contrast, and
/// several criteria had no link at all despite a matching topic sitting there.
final class ContentIntegrityTests: XCTestCase {

    func testEveryTopicIDIsUnique() {
        let ids = LearnContent.all.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "Duplicate topic id.")
    }

    func testEveryCriterionIDIsUnique() {
        let ids = WCAGReference.all.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "Duplicate criterion id.")
    }

    /// A topic citing a criterion number that isn't in the reference is a
    /// dead end for anyone who taps through from the WCAG tool.
    func testEveryTopicCriterionExistsInTheReference() {
        let known = Set(WCAGReference.all.map(\.id))
        for topic in LearnContent.all where topic.wcagRef != "iOS platform" {
            XCTAssertTrue(known.contains(topic.wcagRef),
                          "Topic '\(topic.id)' cites \(topic.wcagRef), which is not in WCAGReference.")
        }
    }

    func testEveryCriterionLinkResolvesToATopic() {
        for c in WCAGReference.all {
            guard let id = c.learnTopicID else { continue }
            XCTAssertNotNil(LearnContent.topic(id: id),
                            "Criterion \(c.id) links to missing topic '\(id)'.")
        }
    }

    /// If a topic cites a criterion, that criterion should link back. A one-way
    /// link means the tool and the dictionary disagree about what covers what.
    func testLinksAreReciprocalWhereTheyCanBe() {
        for topic in LearnContent.all where topic.wcagRef != "iOS platform" {
            guard let c = WCAGReference.all.first(where: { $0.id == topic.wcagRef }) else { continue }
            XCTAssertNotNil(c.learnTopicID,
                            "Criterion \(c.id) is cited by topic '\(topic.id)' but links back to nothing.")
        }
    }

    /// Anything without a real criterion says so with one exact string, so it
    /// can never be mistaken for a number someone invented.
    func testPlatformOnlyTopicsUseTheAgreedMarker() {
        let platform = LearnContent.all.filter { $0.wcagRef == "iOS platform" }
        XCTAssertFalse(platform.isEmpty, "Some topics have no WCAG mapping and should say so.")
        for t in platform {
            XCTAssertFalse(t.wcagTitle.isEmpty, "'\(t.id)' still needs a human-readable source name.")
        }
    }

    /// Criterion ids are the thing people search for, so a malformed one is a
    /// search that silently returns nothing.
    func testCriterionIDsAreWellFormed() {
        for c in WCAGReference.all {
            let parts = c.id.split(separator: ".")
            XCTAssertEqual(parts.count, 3, "\(c.id) is not a three-part criterion number.")
            for p in parts { XCTAssertNotNil(Int(p), "\(c.id) has a non-numeric part.") }
        }
    }

    func testEveryCategoryHasTopics() {
        for cat in AccessibilityCategory.allCases {
            XCTAssertFalse(LearnContent.topics(for: cat).isEmpty, "\(cat.rawValue) has no topics.")
        }
    }

    /// New content has to be reachable by the assistant, not just by browsing.
    func testEveryTopicIsRetrievableByItsOwnTitle() {
        for topic in LearnContent.all {
            let ids = AssistantCorpus.search(topic.title, limit: 5).map(\.passage.id)
            XCTAssertTrue(ids.contains("topic:\(topic.id)"),
                          "'\(topic.title)' does not retrieve its own topic. Got \(ids).")
        }
    }
}
