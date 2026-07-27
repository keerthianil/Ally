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
            summary: "Content reflows to one column without horizontal scrolling.", learnTopicID: "dynamic-type"),
        WCAGCriterion(id: "1.4.11", title: "Non-text Contrast", level: .aa, principle: .perceivable,
            summary: "UI components and meaningful graphics need 3:1 contrast.", learnTopicID: "color-contrast"),

        // Operable
        WCAGCriterion(id: "2.1.1", title: "Keyboard", level: .a, principle: .operable,
            summary: "Everything works with a keyboard or switch, not just touch.", learnTopicID: nil),
        WCAGCriterion(id: "2.2.1", title: "Timing Adjustable", level: .a, principle: .operable,
            summary: "Let people turn off, adjust, or extend time limits.", learnTopicID: nil),
        WCAGCriterion(id: "2.3.3", title: "Animation from Interactions", level: .aaa, principle: .operable,
            summary: "Respect Reduce Motion for non-essential animation.", learnTopicID: nil),
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
            summary: "Focusing something shouldn't trigger an unexpected change.", learnTopicID: nil),
        WCAGCriterion(id: "3.2.3", title: "Consistent Navigation", level: .aa, principle: .understandable,
            summary: "Navigation stays in the same relative order across pages.", learnTopicID: "consistency"),
        WCAGCriterion(id: "3.3.1", title: "Error Identification", level: .a, principle: .understandable,
            summary: "Errors are described in text, clearly and specifically.", learnTopicID: "error-messages"),
        WCAGCriterion(id: "3.3.4", title: "Error Prevention", level: .aa, principle: .understandable,
            summary: "For important actions, allow review, confirm, or undo.", learnTopicID: nil),
        WCAGCriterion(id: "3.3.7", title: "Redundant Entry", level: .a, principle: .understandable,
            summary: "Don't make people re-enter info they already gave you.", learnTopicID: nil),

        // Robust
        WCAGCriterion(id: "4.1.2", title: "Name, Role, Value", level: .a, principle: .robust,
            summary: "Every control exposes its name, role, and state to assistive tech.", learnTopicID: "labels"),
        WCAGCriterion(id: "4.1.3", title: "Status Messages", level: .aa, principle: .robust,
            summary: "Status updates are announced without moving focus.", learnTopicID: nil)
    ]
}
