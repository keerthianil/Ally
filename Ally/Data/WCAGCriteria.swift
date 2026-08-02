import Foundation

/// The WCAG 2.2 success criteria Ally covers, shaped for a *flash card* rather
/// than a document.
///
/// Each criterion carries exactly three short strings and nothing else:
///
/// - `summary` — the rule, in one plain sentence. This is the front of the card.
/// - `mustDo` — the imperative. What you actually change in the app.
/// - `redFlag` — the classic failure, so you can recognise it on sight.
///
/// Anything longer than that belongs in the Learn tab, which is why `learnTopicID`
/// exists. The quick reference is for recall; Learn is for understanding. Keeping
/// that boundary is the whole reason this table is terse.
struct WCAGCriterion: Identifiable, Hashable {
    let id: String            // e.g. "1.4.3"
    let title: String
    let level: Level
    let principle: Principle
    /// The rule, in one sentence. Front of the card.
    let summary: String
    /// The imperative. Back of the card, line one.
    let mustDo: String
    /// The classic failure. Back of the card, line two.
    let redFlag: String
    let learnTopicID: String?

    enum Level: String, CaseIterable, Identifiable, Comparable {
        case a = "A", aa = "AA", aaa = "AAA"
        var id: String { rawValue }

        /// What the level means, said once, so a bare letter never has to be
        /// decoded from memory.
        var meaning: String {
            switch self {
            case .a:   return "The floor"
            case .aa:  return "The legal bar"
            case .aaa: return "Going further"
            }
        }

        static func < (l: Level, r: Level) -> Bool {
            let order: [Level] = [.a, .aa, .aaa]
            return order.firstIndex(of: l)! < order.firstIndex(of: r)!
        }
    }

    enum Principle: String, CaseIterable, Identifiable {
        case perceivable = "Perceivable"
        case operable = "Operable"
        case understandable = "Understandable"
        case robust = "Robust"
        var id: String { rawValue }

        /// The single letter of POUR, for the compact deck picker.
        var initial: String { String(rawValue.prefix(1)) }

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

    static func criterion(id: String) -> WCAGCriterion? { all.first { $0.id == id } }

    static func count(level: WCAGCriterion.Level) -> Int {
        all.filter { $0.level == level }.count
    }

    static let all: [WCAGCriterion] = perceivable + operable + understandable + robust

    // MARK: Perceivable

    static let perceivable: [WCAGCriterion] = [
        WCAGCriterion(id: "1.1.1", title: "Non-text Content", level: .a, principle: .perceivable,
            summary: "Anything that carries meaning without words needs words.",
            mustDo: "Label informative images and icons. Hide decorative ones.",
            redFlag: "An icon button VoiceOver reads as just “button”.",
            learnTopicID: "alt-text"),
        WCAGCriterion(id: "1.2.2", title: "Captions (Prerecorded)", level: .a, principle: .perceivable,
            summary: "Recorded video with sound needs captions.",
            mustDo: "Ship a real caption track, not a link to a transcript.",
            redFlag: "Auto-captions nobody read back.",
            learnTopicID: "captions"),
        WCAGCriterion(id: "1.2.5", title: "Audio Description (Prerecorded)", level: .aa, principle: .perceivable,
            summary: "Say out loud what the video only shows.",
            mustDo: "Add a description track, or write the visuals into the script.",
            redFlag: "A narrator saying “tap this” over an unnamed button.",
            learnTopicID: "audio-description"),
        WCAGCriterion(id: "1.3.1", title: "Info and Relationships", level: .a, principle: .perceivable,
            summary: "Structure you can see has to exist in code as well.",
            mustDo: "Mark headings, group related controls, label every field.",
            redFlag: "A heading that is only bold 20pt text.",
            learnTopicID: "info-relationships"),
        WCAGCriterion(id: "1.3.3", title: "Sensory Characteristics", level: .a, principle: .perceivable,
            summary: "Instructions can't rely on shape, size, position, or sound.",
            mustDo: "Name the control, then say where it is.",
            redFlag: "“Tap the round button on the right.”",
            learnTopicID: "sensory-characteristics"),
        WCAGCriterion(id: "1.3.4", title: "Orientation", level: .aa, principle: .perceivable,
            summary: "Don't lock to one orientation unless the content demands it.",
            mustDo: "Support portrait and landscape on every screen.",
            redFlag: "A portrait-only app on a wheelchair-mounted iPhone.",
            learnTopicID: "orientation"),
        WCAGCriterion(id: "1.3.5", title: "Identify Input Purpose", level: .aa, principle: .perceivable,
            summary: "Tell the system what a field collects so autofill can help.",
            mustDo: "Set textContentType on every name, address, email, and code field.",
            redFlag: "A checkout that never offers the saved card.",
            learnTopicID: "input-purpose"),
        WCAGCriterion(id: "1.4.1", title: "Use of Color", level: .a, principle: .perceivable,
            summary: "Colour can't be the only way you say something.",
            mustDo: "Pair every colour cue with text, an icon, or a shape.",
            redFlag: "A red field border and nothing else.",
            learnTopicID: "color-alone"),
        WCAGCriterion(id: "1.4.2", title: "Audio Control", level: .a, principle: .perceivable,
            summary: "Sound that starts on its own needs a way to stop it.",
            mustDo: "Autoplay muted, or put a visible pause control on screen.",
            redFlag: "A video talking over the top of VoiceOver.",
            learnTopicID: "autoplay-audio"),
        WCAGCriterion(id: "1.4.3", title: "Contrast (Minimum)", level: .aa, principle: .perceivable,
            summary: "Body text 4.5:1. Large text 3:1.",
            mustDo: "Measure it. Never judge contrast by eye on a good screen.",
            redFlag: "Grey placeholder text at 2.8:1.",
            learnTopicID: "color-contrast"),
        WCAGCriterion(id: "1.4.4", title: "Resize Text", level: .aa, principle: .perceivable,
            summary: "Text scales to 200% without losing content or function.",
            mustDo: "Use Dynamic Type styles. Never a fixed point size.",
            redFlag: "A button label clipped to one line at Large.",
            learnTopicID: "dynamic-type"),
        WCAGCriterion(id: "1.4.5", title: "Images of Text", level: .aa, principle: .perceivable,
            summary: "Use real text, not a picture of text.",
            mustDo: "Render type at runtime so it scales and gets read.",
            redFlag: "An onboarding headline baked into a PNG.",
            learnTopicID: "images-of-text"),
        WCAGCriterion(id: "1.4.10", title: "Reflow", level: .aa, principle: .perceivable,
            summary: "Content reflows to one column with no sideways scrolling.",
            mustDo: "Let rows stack into columns as text grows.",
            redFlag: "Two side-by-side buttons at AX5.",
            learnTopicID: "reflow-at-ax-sizes"),
        WCAGCriterion(id: "1.4.11", title: "Non-text Contrast", level: .aa, principle: .perceivable,
            summary: "Controls and meaningful graphics need 3:1.",
            mustDo: "Check borders, icons, toggles, and chart marks too.",
            redFlag: "A pale outline button at 1.6:1.",
            learnTopicID: "non-text-contrast"),
        WCAGCriterion(id: "1.4.12", title: "Text Spacing", level: .aa, principle: .perceivable,
            summary: "Content survives increased line, letter, and word spacing.",
            mustDo: "Let text containers grow. No fixed heights.",
            redFlag: "A card that clips its own second line.",
            learnTopicID: "text-spacing")
    ]

    // MARK: Operable

    static let operable: [WCAGCriterion] = [
        WCAGCriterion(id: "2.1.1", title: "Keyboard", level: .a, principle: .operable,
            summary: "Everything works without a touchscreen.",
            mustDo: "Reach and fire every control with Full Keyboard Access.",
            redFlag: "An action that only exists as a swipe.",
            learnTopicID: "keyboard"),
        WCAGCriterion(id: "2.1.2", title: "No Keyboard Trap", level: .a, principle: .operable,
            summary: "Focus must always be able to leave.",
            mustDo: "Tab into and back out of every sheet, field, and web view.",
            redFlag: "A modal that holds focus until you force-quit.",
            learnTopicID: "keyboard-trap"),
        WCAGCriterion(id: "2.1.4", title: "Character Key Shortcuts", level: .a, principle: .operable,
            summary: "Single-letter shortcuts need an off switch.",
            mustDo: "Require a modifier, allow remapping, or scope it to focus.",
            redFlag: "Typing “r” in a text box fires Reply.",
            learnTopicID: "character-shortcuts"),
        WCAGCriterion(id: "2.2.1", title: "Timing Adjustable", level: .a, principle: .operable,
            summary: "Let people turn off, adjust, or extend any time limit.",
            mustDo: "Warn before a timeout and offer more time.",
            redFlag: "A toast carrying the only Undo, gone in three seconds.",
            learnTopicID: "timeouts"),
        WCAGCriterion(id: "2.2.2", title: "Pause, Stop, Hide", level: .a, principle: .operable,
            summary: "Anything moving for over five seconds needs a pause.",
            mustDo: "Give carousels and tickers a visible stop control.",
            redFlag: "A hero banner that rotates while you are reading it.",
            learnTopicID: "pause-stop-hide"),
        WCAGCriterion(id: "2.3.1", title: "Three Flashes or Below Threshold", level: .a, principle: .operable,
            summary: "Nothing flashes more than three times in one second.",
            mustDo: "Cap flashes at three per second, or design them out.",
            redFlag: "A strobing loading state or a camera-flash transition.",
            learnTopicID: "seizure-safety"),
        WCAGCriterion(id: "2.3.3", title: "Animation from Interactions", level: .aaa, principle: .operable,
            summary: "Respect Reduce Motion for non-essential animation.",
            mustDo: "Swap big motion for a crossfade, never for nothing.",
            redFlag: "A parallax push that ignores the system setting.",
            learnTopicID: "safe-motion"),
        WCAGCriterion(id: "2.4.1", title: "Bypass Blocks", level: .a, principle: .operable,
            summary: "Give people a way past the repeated stuff.",
            mustDo: "Group chrome into containers and mark real headings.",
            redFlag: "Forty swipes through a nav bar to reach the content.",
            learnTopicID: "bypass-blocks"),
        WCAGCriterion(id: "2.4.2", title: "Page Titled", level: .a, principle: .operable,
            summary: "Every screen has a title that describes it.",
            mustDo: "Set a navigation title and mark it as a heading.",
            redFlag: "Four pushed screens that all announce nothing.",
            learnTopicID: "screen-titles"),
        WCAGCriterion(id: "2.4.3", title: "Focus Order", level: .a, principle: .operable,
            summary: "Focus moves in an order that preserves meaning.",
            mustDo: "Match the reading order, then test by swiping right.",
            redFlag: "Focus jumping to the footer after the first field.",
            learnTopicID: "focus-order"),
        WCAGCriterion(id: "2.4.4", title: "Link Purpose (In Context)", level: .a, principle: .operable,
            summary: "A link says where it goes without the sentence around it.",
            mustDo: "Put the destination in the link text itself.",
            redFlag: "A screen of links all reading “Learn more”.",
            learnTopicID: "link-text"),
        WCAGCriterion(id: "2.4.5", title: "Multiple Ways", level: .aa, principle: .operable,
            summary: "More than one route to anything worth finding.",
            mustDo: "Offer search or an index alongside the browse path.",
            redFlag: "Content reachable only by remembering a menu path.",
            learnTopicID: "multiple-ways"),
        WCAGCriterion(id: "2.4.6", title: "Headings and Labels", level: .aa, principle: .operable,
            summary: "Headings and labels describe what they sit above.",
            mustDo: "Write the heading someone would search for.",
            redFlag: "Three sections all titled “Details”.",
            learnTopicID: "headings"),
        WCAGCriterion(id: "2.4.7", title: "Focus Visible", level: .aa, principle: .operable,
            summary: "You can always see which element has focus.",
            mustDo: "Keep the system focus ring, or draw a stronger one.",
            redFlag: "A custom control with no focused state at all.",
            learnTopicID: "focus-visible"),
        WCAGCriterion(id: "2.4.11", title: "Focus Not Obscured (Minimum)", level: .aa, principle: .operable,
            summary: "Your own UI must not cover the focused element.",
            mustDo: "Inset scroll content past sticky bars and the keyboard.",
            redFlag: "Focus sliding under a floating action button.",
            learnTopicID: "focus-not-obscured"),
        WCAGCriterion(id: "2.5.1", title: "Pointer Gestures", level: .a, principle: .operable,
            summary: "Complex gestures need a single-pointer alternative.",
            mustDo: "Add a button for every pinch, swipe, and multi-finger move.",
            redFlag: "Delete that only exists as a precise swipe.",
            learnTopicID: "gestures"),
        WCAGCriterion(id: "2.5.2", title: "Pointer Cancellation", level: .a, principle: .operable,
            summary: "Act on finger-up, so a mis-tap can be slid away from.",
            mustDo: "Never fire on touch-down in a custom gesture.",
            redFlag: "A hand-rolled control that commits the instant you land.",
            learnTopicID: "pointer-cancellation"),
        WCAGCriterion(id: "2.5.3", title: "Label in Name", level: .a, principle: .operable,
            summary: "The accessible name contains the visible text.",
            mustDo: "Start the label with the words printed on the control.",
            redFlag: "A button reading Send, labelled submit_cta.",
            learnTopicID: "label-in-name"),
        WCAGCriterion(id: "2.5.4", title: "Motion Actuation", level: .a, principle: .operable,
            summary: "Shake or tilt features need an ordinary control too.",
            mustDo: "Put the same action on a button, and let people switch motion off.",
            redFlag: "Shake to undo, with no undo anywhere else.",
            learnTopicID: "motion-actuation"),
        WCAGCriterion(id: "2.5.7", title: "Dragging Movements", level: .aa, principle: .operable,
            summary: "Anything you drag needs a single-tap alternative.",
            mustDo: "Add move up and move down buttons beside the drag handle.",
            redFlag: "Reorder-by-drag as the only way to reorder.",
            learnTopicID: "dragging"),
        WCAGCriterion(id: "2.5.8", title: "Target Size (Minimum)", level: .aa, principle: .operable,
            summary: "24×24 CSS px minimum. Apple asks for 44×44 pt.",
            mustDo: "Grow the hit area with contentShape, not just the glyph.",
            redFlag: "A 20pt close button in the corner.",
            learnTopicID: "touch-targets")
    ]

    // MARK: Understandable

    static let understandable: [WCAGCriterion] = [
        WCAGCriterion(id: "3.1.1", title: "Language of Page", level: .a, principle: .understandable,
            summary: "Mark the language so screen readers pronounce it right.",
            mustDo: "Set the language on any string that isn't the app default.",
            redFlag: "A French surname read with an English voice.",
            learnTopicID: "language"),
        WCAGCriterion(id: "3.1.5", title: "Reading Level", level: .aaa, principle: .understandable,
            summary: "Aim below lower-secondary, or offer a simpler version.",
            mustDo: "Shorten sentences before you shorten words.",
            redFlag: "A 30-word sentence in an error message.",
            learnTopicID: "plain-language"),
        WCAGCriterion(id: "3.2.1", title: "On Focus", level: .a, principle: .understandable,
            summary: "Focusing something must not change context.",
            mustDo: "Wait for a deliberate action before navigating.",
            redFlag: "A picker that pushes a screen the moment it is focused.",
            learnTopicID: "predictable"),
        WCAGCriterion(id: "3.2.2", title: "On Input", level: .a, principle: .understandable,
            summary: "Changing a value must not change context.",
            mustDo: "Require a submit action. Never auto-submit on blur.",
            redFlag: "A form that sends itself when the last field loses focus.",
            learnTopicID: "predictable"),
        WCAGCriterion(id: "3.2.3", title: "Consistent Navigation", level: .aa, principle: .understandable,
            summary: "Navigation stays in the same relative order everywhere.",
            mustDo: "Keep the primary action in the same spot on every screen.",
            redFlag: "Save on the left here, on the right there.",
            learnTopicID: "consistency"),
        WCAGCriterion(id: "3.2.6", title: "Consistent Help", level: .a, principle: .understandable,
            summary: "Help sits in the same place on every screen.",
            mustDo: "Pick one location for support and never move it.",
            redFlag: "Contact us hiding in a different menu each time.",
            learnTopicID: "consistent-help"),
        WCAGCriterion(id: "3.3.1", title: "Error Identification", level: .a, principle: .understandable,
            summary: "Errors are described in text, clearly and specifically.",
            mustDo: "Name which field failed, in words, next to the field.",
            redFlag: "“Something went wrong.”",
            learnTopicID: "error-messages"),
        WCAGCriterion(id: "3.3.2", title: "Labels or Instructions", level: .a, principle: .understandable,
            summary: "Inputs get a visible label and their rules up front.",
            mustDo: "Show the format before someone gets it wrong.",
            redFlag: "A placeholder doing the job of a label.",
            learnTopicID: "labels-and-instructions"),
        WCAGCriterion(id: "3.3.3", title: "Error Suggestion", level: .aa, principle: .understandable,
            summary: "If you know the fix, offer it.",
            mustDo: "Say what to type instead, not just that it was wrong.",
            redFlag: "“Invalid date” with no format shown.",
            learnTopicID: "error-suggestion"),
        WCAGCriterion(id: "3.3.4", title: "Error Prevention (Legal, Financial, Data)", level: .aa, principle: .understandable,
            summary: "Money, contracts, and deletions get a review step.",
            mustDo: "Make it reversible, checkable, or confirmed. Pick one.",
            redFlag: "A one-tap Delete Account with no undo.",
            learnTopicID: "error-prevention"),
        WCAGCriterion(id: "3.3.7", title: "Redundant Entry", level: .a, principle: .understandable,
            summary: "Don't make people re-enter what they already gave you.",
            mustDo: "Prefill from earlier steps, or offer a same-as toggle.",
            redFlag: "Retyping the shipping address for billing.",
            learnTopicID: "redundant-entry"),
        WCAGCriterion(id: "3.3.8", title: "Accessible Authentication (Minimum)", level: .aa, principle: .understandable,
            summary: "No memory or puzzle test just to log in.",
            mustDo: "Allow paste, password managers, and Face ID.",
            redFlag: "A CAPTCHA plus a code you must retype from memory.",
            learnTopicID: "accessible-auth")
    ]

    // MARK: Robust

    static let robust: [WCAGCriterion] = [
        WCAGCriterion(id: "4.1.2", title: "Name, Role, Value", level: .a, principle: .robust,
            summary: "Every control exposes its name, role, and state.",
            mustDo: "Give custom controls a label, a trait, and a value.",
            redFlag: "A hand-built toggle that announces neither on nor off.",
            learnTopicID: "labels"),
        WCAGCriterion(id: "4.1.3", title: "Status Messages", level: .aa, principle: .robust,
            summary: "Status updates are announced without moving focus.",
            mustDo: "Post an announcement when something finishes or fails.",
            redFlag: "A silent Saved toast.",
            learnTopicID: "status-messages")
    ]
}
