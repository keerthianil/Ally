import XCTest

/// What VoiceOver will actually say, screen by screen.
///
/// Apple's `performAccessibilityAudit` (see `AllyAccessibilityAuditTests`) checks
/// that elements *have* labels. It does not check that the labels are any good,
/// and the two most common ways an app is miserable under VoiceOver both survive
/// an audit cleanly:
///
/// - A label that is the SF Symbol name, or the raw string id, rather than words.
///   "chevron.right" and "submit_cta" are labels. They pass. They are useless.
/// - Two controls on one screen with the same label. Voice Control users say
///   "Tap Open" and get a disambiguation grid; VoiceOver users hear the same
///   phrase four times and cannot tell the rows apart.
///
/// So this walks the real tree and reads it the way a person would. It is not a
/// substitute for putting VoiceOver on a physical phone, which is the only place
/// gesture behaviour and announcement timing can really be judged, but it does
/// catch the regressions that get shipped.
final class VoiceOverContractTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    // MARK: Screens

    @MainActor
    func testLearnHomeSpeaks() throws {
        let app = launch(["-skipOnboarding"])
        try assertSpeaks(app, screen: "Learn")
    }

    @MainActor
    func testCheckHomeSpeaks() throws {
        let app = launch(["-resetStore", "-seedDemo", "-tabCheck"])
        try assertSpeaks(app, screen: "Check")
    }

    @MainActor
    func testToolkitSpeaks() throws {
        let app = launch(["-skipOnboarding", "-tabToolkit"])
        try assertSpeaks(app, screen: "Toolkit")
    }

    @MainActor
    func testReportSpeaks() throws {
        let app = launch(["-seedDemo", "-openResult"])
        try assertSpeaks(app, screen: "Report")
    }

    @MainActor
    func testFlashCardDeckSpeaks() throws {
        let app = launch(["-openTool", "wcag"])
        try assertSpeaks(app, screen: "WCAG deck")
    }

    @MainActor
    func testOnboardingSpeaks() throws {
        let app = launch(["-showOnboarding"])
        try assertSpeaks(app, screen: "Onboarding")
    }

    // MARK: The card is one utterance, and it can be activated

    /// The card is a plain view carrying an `.isButton` trait, so its activation
    /// comes from an explicit accessibility action rather than from the tap
    /// gesture. If that regresses, VoiceOver users can see the card and can never
    /// turn it over.
    @MainActor
    func testFlashCardIsOneElementAndCarriesItsWholeRule() throws {
        let app = launch(["-openTool", "wcag"])
        let card = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "1.1.1")).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 5), "The card should be one focusable element.")

        // One utterance: number, name, level, principle, and the rule.
        for fragment in ["1.1.1", "Non-text Content", "Level A", "Perceivable"] {
            XCTAssertTrue(card.label.contains(fragment),
                          "The card's spoken label is missing '\(fragment)'. Got: \(card.label)")
        }

        // The face that is turned away must not be live. An `.opacity(0)` view is
        // still hit-testable in SwiftUI, so the back's Learn button used to sit
        // active underneath the front of the card.
        //
        // Asserted on hittability rather than existence on purpose: XCUITest
        // surfaces SwiftUI text nodes that are not accessibility elements and
        // that VoiceOver never reaches, so `exists` is the wrong question. What
        // matters is that nothing behind the card can be focused or tapped.
        let hiddenFaceButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "The why, in Learn")).firstMatch
        XCTAssertFalse(hiddenFaceButton.isHittable,
                       "The back of the card is live while the card is face up.")

        app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Show the fix"))
            .firstMatch.tap()
        XCTAssertTrue(hiddenFaceButton.waitForExistence(timeout: 3) && hiddenFaceButton.isHittable,
                      "After flipping, the back's Learn link should be reachable.")
    }

    /// Three real buttons, because the deck must not be swipe-only (WCAG 2.5.1),
    /// and under VoiceOver the swipe belongs to VoiceOver anyway.
    @MainActor
    func testDeckIsOperableWithoutTheSwipeGesture() throws {
        let app = launch(["-openTool", "wcag"])
        for label in ["Previous", "Next"] {
            let button = app.buttons[label].firstMatch
            XCTAssertTrue(button.waitForExistence(timeout: 5),
                          "'\(label)' is missing. The deck would be swipe-only.")
            XCTAssertTrue(button.isHittable)
        }
        let flip = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Show the fix")).firstMatch
        XCTAssertTrue(flip.waitForExistence(timeout: 3))

        // Moving the deck with the buttons alone has to actually move it.
        let first = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "1.1.1")).firstMatch
        XCTAssertTrue(first.exists)
        app.buttons["Next"].firstMatch.tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "1.2.2"))
            .firstMatch.waitForExistence(timeout: 3), "Next did not advance the deck.")
    }

    /// The bar is the only way between tabs, so its three items must always be
    /// named and reachable. This is the check that would have caught the bar
    /// collapsing itself out of reach.
    @MainActor
    func testTabBarIsAlwaysNamedAndReachable() throws {
        let app = launch(["-skipOnboarding"])
        for tab in ["Learn", "Check", "Toolkit"] {
            let button = app.buttons[tab].firstMatch
            XCTAssertTrue(button.waitForExistence(timeout: 5), "Tab '\(tab)' is not reachable.")
            XCTAssertTrue(button.isHittable, "Tab '\(tab)' is not hittable.")
        }
    }

    /// The bar goes away on a pushed screen, so that screen has to provide its own
    /// way out. A screen with neither is a trap.
    @MainActor
    func testEveryPushedScreenHasAWayBack() throws {
        let app = launch(["-seedDemo", "-openResult"])
        XCTAssertTrue(app.navigationBars.buttons.firstMatch.waitForExistence(timeout: 5),
                      "The report hides the tab bar and offers no back button.")

        let celebration = launch(["-seedDemo", "-openCelebration"])
        // The celebration screen deliberately has no back button: it is a one-way
        // step into the report. Its single forward control therefore has to be
        // present and named.
        let onward = celebration.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "See Your Report")).firstMatch
        XCTAssertTrue(onward.waitForExistence(timeout: 5),
                      "The celebration screen has no tab bar, no back button, and no way forward.")
        XCTAssertTrue(onward.isHittable)
    }

    // MARK: Helpers

    @MainActor
    private func launch(_ args: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = args
        app.launch()
        return app
    }

    /// Symbol names, identifiers, and other things that are technically a label.
    private func isNotWords(_ label: String) -> Bool {
        let l = label.trimmingCharacters(in: .whitespaces)
        if l.isEmpty { return true }
        // "chevron.right", "arrow.up.forward.square" — dotted, no spaces.
        if !l.contains(" ") && l.contains(".") && l.rangeOfCharacter(from: .decimalDigits) == nil {
            return true
        }
        // "submit_cta", "learn-topic-detail"
        if l.contains("_") { return true }
        return false
    }

    @MainActor
    private func assertSpeaks(_ app: XCUIApplication, screen: String) throws {
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        // Let the entrance animations settle so nothing is measured mid-fade.
        sleep(2)

        let controls = app.descendants(matching: .button).allElementsBoundByIndex
            + app.descendants(matching: .textField).allElementsBoundByIndex

        var seen: [String: Int] = [:]
        for control in controls where control.exists && control.isHittable {
            let label = control.label
            XCTAssertFalse(isNotWords(label),
                           "\(screen): a control speaks as '\(label)', which is an identifier, not words.")
            seen[label, default: 0] += 1
        }

        XCTAssertFalse(controls.isEmpty, "\(screen): no controls found. The walk did not reach the screen.")

        // Duplicates are the Voice Control failure: "Tap Open" with four Opens on
        // screen. A couple of exact repeats can be legitimate (a list of identical
        // affordances), so this reports rather than being absolute about three.
        let ambiguous = seen.filter { $0.value > 3 }
        XCTAssertTrue(ambiguous.isEmpty,
                      "\(screen): \(ambiguous.map { "'\($0.key)' ×\($0.value)" }.joined(separator: ", ")) "
                      + "— Voice Control cannot disambiguate these by name.")
    }
}
