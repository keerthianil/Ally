import Foundation

/// A curated slice of WCAG 2.2 success criteria for the Toolkit's quick reference.
/// Grouped by the four POUR principles; each has a plain-English summary and (where
/// one exists) a deep-link into the matching Learn topic.
struct WCAGCriterion: Identifiable, Hashable {
    let id: String            // e.g. "1.4.3"
    let title: String
    let level: Level
    let principle: Principle
    let summary: String       // plain English
    let learnTopicID: String?

    enum Level: String, CaseIterable, Identifiable { case a = "A", aa = "AA", aaa = "AAA"; var id: String { rawValue } }
    enum Principle: String, CaseIterable, Identifiable {
        case perceivable = "Perceivable"
        case operable = "Operable"
        case understandable = "Understandable"
        case robust = "Robust"
        var id: String { rawValue }
        var blurb: String {
            switch self {
            case .perceivable:    return "Users can perceive the content."
            case .operable:       return "Users can operate the interface."
            case .understandable: return "Users can understand it."
            case .robust:         return "It works with assistive tech."
            }
        }
    }
}

enum WCAGReference {
    static func criteria(for principle: WCAGCriterion.Principle) -> [WCAGCriterion] {
        all.filter { $0.principle == principle }
    }

    static let all: [WCAGCriterion] = [
        // Perceivable
        WCAGCriterion(id: "1.1.1", title: "Non-text Content", level: .a, principle: .perceivable,
            summary: "Images and icons that carry meaning need a text alternative.", learnTopicID: "labels"),
        WCAGCriterion(id: "1.3.1", title: "Info and Relationships", level: .a, principle: .perceivable,
            summary: "Structure like headings and lists must be conveyed in code, not just visually.", learnTopicID: "headings"),
        WCAGCriterion(id: "1.4.1", title: "Use of Color", level: .a, principle: .perceivable,
            summary: "Color can't be the only way you communicate something.", learnTopicID: "color-alone"),
        WCAGCriterion(id: "1.4.3", title: "Contrast (Minimum)", level: .aa, principle: .perceivable,
            summary: "Text needs at least 4.5:1 contrast (3:1 for large text).", learnTopicID: "color-contrast"),
        WCAGCriterion(id: "1.4.4", title: "Resize Text", level: .aa, principle: .perceivable,
            summary: "Text must scale to 200% without loss of content or function.", learnTopicID: "dynamic-type"),
        WCAGCriterion(id: "1.4.10", title: "Reflow", level: .aa, principle: .perceivable,
            summary: "Content reflows to one column without horizontal scrolling.", learnTopicID: "reflow-at-ax-sizes"),
        WCAGCriterion(id: "1.4.11", title: "Non-text Contrast", level: .aa, principle: .perceivable,
            summary: "UI components and meaningful graphics need 3:1 contrast.", learnTopicID: "non-text-contrast"),

        // Operable
        WCAGCriterion(id: "2.1.1", title: "Keyboard", level: .a, principle: .operable,
            summary: "Everything works with a keyboard or switch, not just touch.", learnTopicID: "keyboard"),
        WCAGCriterion(id: "2.2.1", title: "Timing Adjustable", level: .a, principle: .operable,
            summary: "Let people turn off, adjust, or extend time limits.", learnTopicID: "timeouts"),
        WCAGCriterion(id: "2.3.3", title: "Animation from Interactions", level: .aaa, principle: .operable,
            summary: "Respect Reduce Motion for non-essential animation.", learnTopicID: "safe-motion"),
        WCAGCriterion(id: "2.4.3", title: "Focus Order", level: .a, principle: .operable,
            summary: "Focus moves in an order that preserves meaning.", learnTopicID: "focus-order"),
        WCAGCriterion(id: "2.4.6", title: "Headings and Labels", level: .aa, principle: .operable,
            summary: "Headings and labels describe topic or purpose.", learnTopicID: "headings"),
        WCAGCriterion(id: "2.5.1", title: "Pointer Gestures", level: .a, principle: .operable,
            summary: "Complex gestures need a single-pointer alternative.", learnTopicID: "gestures"),
        WCAGCriterion(id: "2.5.8", title: "Target Size (Minimum)", level: .aa, principle: .operable,
            summary: "Targets are at least 24×24 CSS px (Apple recommends 44pt).", learnTopicID: "touch-targets"),

        // Understandable
        WCAGCriterion(id: "3.1.5", title: "Reading Level", level: .aaa, principle: .understandable,
            summary: "Aim for a lower-secondary reading level, or offer a simpler version.", learnTopicID: "plain-language"),
        WCAGCriterion(id: "3.2.1", title: "On Focus", level: .a, principle: .understandable,
            summary: "Focusing something shouldn't trigger an unexpected change.", learnTopicID: "predictable"),
        WCAGCriterion(id: "3.2.3", title: "Consistent Navigation", level: .aa, principle: .understandable,
            summary: "Navigation stays in the same relative order across pages.", learnTopicID: "consistency"),
        WCAGCriterion(id: "3.3.1", title: "Error Identification", level: .a, principle: .understandable,
            summary: "Errors are described in text, clearly and specifically.", learnTopicID: "error-messages"),
        WCAGCriterion(id: "3.3.4", title: "Error Prevention", level: .aa, principle: .understandable,
            summary: "For important actions, allow review, confirm, or undo.", learnTopicID: "error-messages"),
        WCAGCriterion(id: "3.3.7", title: "Redundant Entry", level: .a, principle: .understandable,
            summary: "Don't make people re-enter info they already gave you.", learnTopicID: "redundant-entry"),

        // Robust
        WCAGCriterion(id: "4.1.2", title: "Name, Role, Value", level: .a, principle: .robust,
            summary: "Every control exposes its name, role, and state to assistive tech.", learnTopicID: "labels"),
        WCAGCriterion(id: "4.1.3", title: "Status Messages", level: .aa, principle: .robust,
            summary: "Status updates are announced without moving focus.", learnTopicID: "status-messages"),

        // Added August 2026. Each of these is referenced by a Learn topic, and
        // without the entry the topic's deep link into the reference dead-ends.
        WCAGCriterion(id: "1.2.2", title: "Captions (Prerecorded)", level: .a, principle: .perceivable,
            summary: "Recorded video with sound needs captions.", learnTopicID: "captions"),
        WCAGCriterion(id: "1.3.4", title: "Orientation", level: .aa, principle: .perceivable,
            summary: "Don't lock to one orientation unless the content demands it.", learnTopicID: "orientation"),
        WCAGCriterion(id: "1.3.5", title: "Identify Input Purpose", level: .aa, principle: .perceivable,
            summary: "Tell the system what a field collects so autofill can help.", learnTopicID: "input-purpose"),
        WCAGCriterion(id: "1.4.5", title: "Images of Text", level: .aa, principle: .perceivable,
            summary: "Use real text rather than a picture of text.", learnTopicID: "images-of-text"),
        WCAGCriterion(id: "1.4.12", title: "Text Spacing", level: .aa, principle: .perceivable,
            summary: "Content survives increased line, letter, and word spacing.", learnTopicID: "text-spacing"),
        WCAGCriterion(id: "2.2.2", title: "Pause, Stop, Hide", level: .a, principle: .operable,
            summary: "Anything moving for more than five seconds needs a pause.", learnTopicID: "pause-stop-hide"),
        WCAGCriterion(id: "2.4.2", title: "Page Titled", level: .a, principle: .operable,
            summary: "Every screen has a title that describes it.", learnTopicID: "screen-titles"),
        WCAGCriterion(id: "2.4.4", title: "Link Purpose (In Context)", level: .a, principle: .operable,
            summary: "A link says where it goes without needing the sentence around it.", learnTopicID: "link-text"),
        WCAGCriterion(id: "2.4.7", title: "Focus Visible", level: .aa, principle: .operable,
            summary: "You can always see which element has focus.", learnTopicID: "focus-visible"),
        WCAGCriterion(id: "2.4.11", title: "Focus Not Obscured (Minimum)", level: .aa, principle: .operable,
            summary: "Your own UI must not cover the element that has focus.", learnTopicID: "focus-not-obscured"),
        WCAGCriterion(id: "2.5.2", title: "Pointer Cancellation", level: .a, principle: .operable,
            summary: "Act on finger-up, so a mis-tap can be slid away from.", learnTopicID: "pointer-cancellation"),
        WCAGCriterion(id: "2.5.3", title: "Label in Name", level: .a, principle: .operable,
            summary: "The accessible name contains the visible text.", learnTopicID: "label-in-name"),
        WCAGCriterion(id: "2.5.4", title: "Motion Actuation", level: .a, principle: .operable,
            summary: "Shake or tilt features need an ordinary control too.", learnTopicID: "motion-actuation"),
        WCAGCriterion(id: "2.5.7", title: "Dragging Movements", level: .aa, principle: .operable,
            summary: "Anything you drag needs a single-tap alternative.", learnTopicID: "dragging"),
        WCAGCriterion(id: "3.1.1", title: "Language of Page", level: .a, principle: .understandable,
            summary: "Mark the language so screen readers pronounce it correctly.", learnTopicID: "language"),
        WCAGCriterion(id: "3.2.2", title: "On Input", level: .a, principle: .understandable,
            summary: "Changing a setting shouldn't change context unexpectedly.", learnTopicID: "predictable"),
        WCAGCriterion(id: "3.2.6", title: "Consistent Help", level: .a, principle: .understandable,
            summary: "Help sits in the same place on every screen.", learnTopicID: "consistent-help"),
        WCAGCriterion(id: "3.3.2", title: "Labels or Instructions", level: .a, principle: .understandable,
            summary: "Inputs get a visible label and their rules up front.", learnTopicID: "labels-and-instructions"),
        WCAGCriterion(id: "3.3.8", title: "Accessible Authentication (Minimum)", level: .aa, principle: .understandable,
            summary: "No memory or puzzle test just to log in.", learnTopicID: "accessible-auth")
    ]
}
