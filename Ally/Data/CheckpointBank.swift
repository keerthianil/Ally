import Foundation

/// One self-assessment question. Deliberately plain-English — never WCAG jargon —
/// but each carries the criterion it maps to and the Learn topic it deep-links to
/// so a failing answer becomes a learning moment.
struct CheckpointItem: Identifiable, Hashable {
    let id: String
    let category: AccessibilityCategory
    let question: String
    let helper: String            // one line of "what good looks like"
    let wcagRef: String
    let wcagTitle: String
    let learnTopicID: String?     // deep-link target in the Learn tab

    static func == (l: CheckpointItem, r: CheckpointItem) -> Bool { l.id == r.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// The static question set. Five checkpoints per category (20 total) — enough to
/// feel thorough in a few minutes without becoming a chore.
enum CheckpointBank {
    static let all: [CheckpointItem] = vision + motor + cognitive + navigation

    static func items(for category: AccessibilityCategory) -> [CheckpointItem] {
        all.filter { $0.category == category }
    }

    static func item(id: String) -> CheckpointItem? { all.first { $0.id == id } }

    static let vision: [CheckpointItem] = [
        CheckpointItem(id: "v-contrast", category: .vision,
            question: "Does your text have enough contrast against its background?",
            helper: "Body text should hit at least a 4.5:1 ratio.",
            wcagRef: "1.4.3", wcagTitle: "Contrast (Minimum)", learnTopicID: "color-contrast"),
        CheckpointItem(id: "v-resize", category: .vision,
            question: "Can users read all text without zooming in?",
            helper: "Text should scale with the system Larger Text setting.",
            wcagRef: "1.4.4", wcagTitle: "Resize Text", learnTopicID: "dynamic-type"),
        CheckpointItem(id: "v-color", category: .vision,
            question: "Can someone use the app without relying on color?",
            helper: "Pair color with text, icons, or shape.",
            wcagRef: "1.4.1", wcagTitle: "Use of Color", learnTopicID: "color-alone"),
        CheckpointItem(id: "v-alt", category: .vision,
            question: "Do meaningful images have text descriptions?",
            helper: "Decorative images can be hidden; informative ones need labels.",
            wcagRef: "1.1.1", wcagTitle: "Non-text Content", learnTopicID: "labels"),
        CheckpointItem(id: "v-reflow", category: .vision,
            question: "Does content reflow without side-scrolling at large text?",
            helper: "Nothing should get clipped when text is enlarged.",
            wcagRef: "1.4.10", wcagTitle: "Reflow", learnTopicID: "dynamic-type")
    ]

    static let motor: [CheckpointItem] = [
        CheckpointItem(id: "m-target", category: .motor,
            question: "Are tappable elements at least 44×44 points?",
            helper: "Small targets cause mis-taps for many users.",
            wcagRef: "2.5.8", wcagTitle: "Target Size (Minimum)", learnTopicID: "touch-targets"),
        CheckpointItem(id: "m-gesture", category: .motor,
            question: "Does every complex gesture have a simple tap alternative?",
            helper: "Swipes and pinches shouldn't be the only way to do something.",
            wcagRef: "2.5.1", wcagTitle: "Pointer Gestures", learnTopicID: "gestures"),
        CheckpointItem(id: "m-undo", category: .motor,
            question: "Can users undo or confirm destructive actions?",
            helper: "Accidental taps shouldn't be irreversible.",
            wcagRef: "3.3.4", wcagTitle: "Error Prevention", learnTopicID: nil),
        CheckpointItem(id: "m-spacing", category: .motor,
            question: "Is there enough space between interactive elements?",
            helper: "Crowded controls are hard to hit accurately.",
            wcagRef: "2.5.8", wcagTitle: "Target Size (Minimum)", learnTopicID: "touch-targets"),
        CheckpointItem(id: "m-timing", category: .motor,
            question: "Can the app be used without racing a timer?",
            helper: "Avoid time limits, or let people extend them.",
            wcagRef: "2.2.1", wcagTitle: "Timing Adjustable", learnTopicID: nil)
    ]

    static let cognitive: [CheckpointItem] = [
        CheckpointItem(id: "c-plain", category: .cognitive,
            question: "Is your writing clear and free of jargon?",
            helper: "Aim for language a distracted person can follow.",
            wcagRef: "3.1.5", wcagTitle: "Reading Level", learnTopicID: "plain-language"),
        CheckpointItem(id: "c-errors", category: .cognitive,
            question: "Do error messages say what went wrong and how to fix it?",
            helper: "Name the problem and the next step.",
            wcagRef: "3.3.1", wcagTitle: "Error Identification", learnTopicID: "error-messages"),
        CheckpointItem(id: "c-consistent", category: .cognitive,
            question: "Are layout and navigation consistent across screens?",
            helper: "The same action should live in the same place.",
            wcagRef: "3.2.3", wcagTitle: "Consistent Navigation", learnTopicID: "consistency"),
        CheckpointItem(id: "c-predictable", category: .cognitive,
            question: "Does the app avoid surprising changes on focus or input?",
            helper: "Don't auto-submit or jump the user somewhere unexpected.",
            wcagRef: "3.2.1", wcagTitle: "On Focus", learnTopicID: nil),
        CheckpointItem(id: "c-memory", category: .cognitive,
            question: "Do you keep key info visible instead of relying on memory?",
            helper: "Don't make people memorize a code from a previous screen.",
            wcagRef: "3.3.7", wcagTitle: "Redundant Entry", learnTopicID: nil)
    ]

    static let navigation: [CheckpointItem] = [
        CheckpointItem(id: "n-focus", category: .navigation,
            question: "Does VoiceOver move through content in a logical order?",
            helper: "Focus should follow the visual reading order.",
            wcagRef: "2.4.3", wcagTitle: "Focus Order", learnTopicID: "focus-order"),
        CheckpointItem(id: "n-labels", category: .navigation,
            question: "Does every button and icon have a meaningful name?",
            helper: "\"Button\" tells a screen-reader user nothing.",
            wcagRef: "4.1.2", wcagTitle: "Name, Role, Value", learnTopicID: "labels"),
        CheckpointItem(id: "n-headings", category: .navigation,
            question: "Are section titles marked as headings?",
            helper: "Headings let people jump around instead of reading everything.",
            wcagRef: "2.4.6", wcagTitle: "Headings and Labels", learnTopicID: "headings"),
        CheckpointItem(id: "n-location", category: .navigation,
            question: "Can users always tell where they are?",
            helper: "Clear titles and a predictable way back.",
            wcagRef: "2.4.8", wcagTitle: "Location", learnTopicID: nil),
        CheckpointItem(id: "n-status", category: .navigation,
            question: "Are status changes announced (loading, success, errors)?",
            helper: "Use live regions so screen readers hear updates.",
            wcagRef: "4.1.3", wcagTitle: "Status Messages", learnTopicID: nil)
    ]
}
