import SwiftUI

/// A single Learn entry. Plain-English first; the WCAG reference is intentionally
/// secondary (for people who want the spec). Each topic can carry an interactive
/// `demo` so the concept is *felt*, not just read.
struct LearnTopic: Identifiable, Hashable {
    let id: String                 // slug, also used for progress tracking
    let category: AccessibilityCategory
    let title: String
    let whatItIs: String           // one sentence, zero jargon
    let whoItHurts: String         // real humans, not abstract compliance
    let whyItMatters: String
    let wcagRef: String            // e.g. "1.4.3"
    let wcagTitle: String          // e.g. "Contrast (Minimum)"
    let testYourself: String       // a quick action they can do right now
    let demo: LearnDemo

    static func == (l: LearnTopic, r: LearnTopic) -> Bool { l.id == r.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// The interactive demonstration attached to a topic. `TopicDetailView` renders
/// the matching demo; `.none` topics just show the written guidance.
enum LearnDemo: Hashable {
    case contrast(goodFG: UInt32, goodBG: UInt32, badFG: UInt32, badBG: UInt32)
    case touchTarget
    case textReveal(before: String, after: String, caption: String)
    case colorOnly
    case none
}

/// Static Learn database. Seeded set covering all four categories; expands toward
/// the full 25–30 topics as content architecture (doc 05) is finalized.
enum LearnContent {
    static let all: [LearnTopic] = vision + motor + cognitive + navigation

    static func topics(for category: AccessibilityCategory) -> [LearnTopic] {
        all.filter { $0.category == category }
    }

    static func topic(id: String) -> LearnTopic? { all.first { $0.id == id } }

    // MARK: Vision
    static let vision: [LearnTopic] = [
        LearnTopic(
            id: "color-contrast",
            category: .vision,
            title: "Color Contrast",
            whatItIs: "Text needs enough contrast against its background to be read.",
            whoItHurts: "People with low vision, aging eyes, or anyone using a phone in bright sun.",
            whyItMatters: "Low-contrast text is the single most common accessibility failure on the web — it quietly excludes millions.",
            wcagRef: "1.4.3",
            wcagTitle: "Contrast (Minimum)",
            testYourself: "Turn your screen brightness to 20% and step outside. Can you still read it?",
            demo: .contrast(goodFG: 0x1A0E22, goodBG: 0xFDF4FA, badFG: 0xBFA9C6, badBG: 0xFDF4FA)
        ),
        LearnTopic(
            id: "color-alone",
            category: .vision,
            title: "Don't Rely on Color Alone",
            whatItIs: "Never use color as the only way to convey meaning.",
            whoItHurts: "The ~1 in 12 men (and 1 in 200 women) with color blindness.",
            whyItMatters: "A red 'error' and green 'success' look identical to someone with deuteranopia — they need text or icons too.",
            wcagRef: "1.4.1",
            wcagTitle: "Use of Color",
            testYourself: "Screenshot your app and open it in the Toolkit's color-blindness simulator.",
            demo: .colorOnly
        ),
        LearnTopic(
            id: "dynamic-type",
            category: .vision,
            title: "Resizable Text",
            whatItIs: "Users must be able to scale text up without breaking the layout.",
            whoItHurts: "Anyone who bumps up their font size — a huge and growing group as people age.",
            whyItMatters: "If text is locked at a fixed size, ~1 in 3 users who enlarge system text simply can't use your app comfortably.",
            wcagRef: "1.4.4",
            wcagTitle: "Resize Text",
            testYourself: "Set Larger Text to max in Settings → Accessibility. Does this screen still work?",
            demo: .textReveal(before: "Fixed 11pt caption text", after: "Scales with the reader", caption: "Left ignores Dynamic Type; right respects it.")
        ),
        LearnTopic(
            id: "non-text-contrast",
            category: .vision,
            title: "Non-Text Contrast",
            whatItIs: "Buttons, icons, and input borders need enough contrast too — not just text.",
            whoItHurts: "Low-vision users who can't find a button that blends into the background.",
            whyItMatters: "A pale outline-only button at 1.5:1 is invisible to many people. UI elements need at least 3:1.",
            wcagRef: "1.4.11",
            wcagTitle: "Non-text Contrast",
            testYourself: "Check your buttons' borders and icons against the Toolkit contrast checker at 3:1.",
            demo: .contrast(goodFG: 0x0A93AE, goodBG: 0xFDF4FA, badFG: 0xCDEFF5, badBG: 0xFDF4FA)
        ),
        LearnTopic(
            id: "text-spacing",
            category: .vision,
            title: "Text Spacing",
            whatItIs: "Layouts shouldn't break when users increase line height or letter spacing.",
            whoItHurts: "People with dyslexia who space text out to read more comfortably.",
            whyItMatters: "If your text is in fixed-height boxes, spacing overrides clip it — and the content is lost.",
            wcagRef: "1.4.12",
            wcagTitle: "Text Spacing",
            testYourself: "Avoid fixed heights on text containers; let them grow.",
            demo: .none
        ),
        LearnTopic(
            id: "captions",
            category: .vision,
            title: "Captions for Video",
            whatItIs: "Any spoken audio in video needs synchronized captions.",
            whoItHurts: "Deaf and hard-of-hearing users — and anyone watching with the sound off.",
            whyItMatters: "Without captions, video content is simply inaccessible to a large audience.",
            wcagRef: "1.2.2",
            wcagTitle: "Captions (Prerecorded)",
            testYourself: "Mute every video in your app. Can you still follow it?",
            demo: .none
        ),
        LearnTopic(
            id: "images-of-text",
            category: .vision,
            title: "Avoid Images of Text",
            whatItIs: "Use real text, not pictures of text, wherever possible.",
            whoItHurts: "People who resize text or use screen readers — images don't scale or get read.",
            whyItMatters: "Text baked into an image gets blurry when enlarged and is invisible to VoiceOver.",
            wcagRef: "1.4.5",
            wcagTitle: "Images of Text",
            testYourself: "Find any text living inside an image asset — could it be real text instead?",
            demo: .none
        ),
        LearnTopic(
            id: "contrast-settings",
            category: .vision,
            title: "Respect Increase Contrast",
            whatItIs: "iOS lets people ask for stronger contrast and solid backgrounds, and your app has to actually change when they do.",
            whoItHurts: "Low-vision users, people with cataracts, and anyone with glare sensitivity, who turn these on system wide.",
            whyItMatters: "Blur and translucency look great in a design review and dissolve in real use. When these settings are on, go fully opaque and stop using blur to separate layers.",
            wcagRef: "iOS platform",
            wcagTitle: "Increase Contrast and Reduce Transparency",
            testYourself: "Settings, Accessibility, Display and Text Size. Turn on Increase Contrast and Reduce Transparency, then reopen every screen that uses a blur.",
            demo: .none
        ),
        LearnTopic(
            id: "reflow-at-ax-sizes",
            category: .vision,
            title: "Survive the Biggest Text Size",
            whatItIs: "Your layout has to reflow into one readable column at the largest accessibility text sizes, with no sideways scrolling.",
            whoItHurts: "People who run their phone at AX3 or AX5 every day, often older users and people with low vision.",
            whyItMatters: "Supporting Dynamic Type is not the same as surviving it. Side-by-side buttons and fixed-height cards break long before AX5.",
            wcagRef: "1.4.10",
            wcagTitle: "Reflow",
            testYourself: "Settings, Accessibility, Larger Text. Switch on Larger Accessibility Sizes, drag to maximum, then walk every screen.",
            demo: .none
        )
    ]

    // MARK: Motor
    static let motor: [LearnTopic] = [
        LearnTopic(
            id: "touch-targets",
            category: .motor,
            title: "Touch Target Size",
            whatItIs: "Tappable things should be big enough to hit reliably.",
            whoItHurts: "People with tremors, limited dexterity, or just large fingers on a moving train.",
            whyItMatters: "Tiny targets cause mis-taps and frustration. Apple's minimum is 44×44 pt; WCAG asks for at least 24×24.",
            wcagRef: "2.5.8",
            wcagTitle: "Target Size (Minimum)",
            testYourself: "Try tapping your smallest button with your thumb while walking.",
            demo: .touchTarget
        ),
        LearnTopic(
            id: "gestures",
            category: .motor,
            title: "Simple Gestures",
            whatItIs: "Anything done with a complex gesture needs a simple single-tap alternative.",
            whoItHurts: "People who can't perform pinches, swipes, or multi-finger gestures.",
            whyItMatters: "If deleting an item only works via a precise swipe, some users can never delete anything.",
            wcagRef: "2.5.1",
            wcagTitle: "Pointer Gestures",
            testYourself: "List every action in your app that requires a swipe or pinch — does each have a button too?",
            demo: .none
        ),
        LearnTopic(
            id: "keyboard",
            category: .motor,
            title: "Keyboard & Switch Access",
            whatItIs: "Everything must work without a touchscreen — via keyboard or switch control.",
            whoItHurts: "People who navigate with a switch, keyboard, or other assistive input.",
            whyItMatters: "If an action is touch-only, switch-control users are locked out of it entirely.",
            wcagRef: "2.1.1",
            wcagTitle: "Keyboard",
            testYourself: "Turn on Full Keyboard Access and try to reach every control with Tab.",
            demo: .none
        ),
        LearnTopic(
            id: "dragging",
            category: .motor,
            title: "Dragging Alternatives",
            whatItIs: "Anything you drag should also be doable without dragging.",
            whoItHurts: "People who can't hold a precise press-and-drag — tremor, one hand, a stylus.",
            whyItMatters: "Reorder-by-drag with no alternative means some users can never reorder. New in WCAG 2.2.",
            wcagRef: "2.5.7",
            wcagTitle: "Dragging Movements",
            testYourself: "For each drag interaction, add tap-based buttons (e.g. move up/down).",
            demo: .none
        ),
        LearnTopic(
            id: "timeouts",
            category: .motor,
            title: "Enough Time",
            whatItIs: "Don't force people to act within a tight time limit.",
            whoItHurts: "Anyone who reads or moves slowly, or gets interrupted mid-task.",
            whyItMatters: "Auto-dismissing dialogs and countdowns punish people for needing more time.",
            wcagRef: "2.2.1",
            wcagTitle: "Timing Adjustable",
            testYourself: "Find any countdown or auto-dismiss — can it be paused or extended?",
            demo: .none
        ),
        LearnTopic(
            id: "motion-actuation",
            category: .motor,
            title: "Motion Isn't the Only Way",
            whatItIs: "Features triggered by moving the device need a regular control too.",
            whoItHurts: "People who can't shake, tilt, or move their phone freely.",
            whyItMatters: "\"Shake to undo\" with no button is unusable for someone with the phone mounted.",
            wcagRef: "2.5.4",
            wcagTitle: "Motion Actuation",
            testYourself: "Does every shake/tilt gesture have an on-screen equivalent?",
            demo: .none
        ),
        LearnTopic(
            id: "orientation",
            category: .motor,
            title: "Work in Both Orientations",
            whatItIs: "Do not lock your app to portrait unless the content genuinely requires one orientation.",
            whoItHurts: "People whose iPhone is clamped to a wheelchair, a bed mount, or a desk arm in a position they cannot rotate.",
            whyItMatters: "If the phone is mounted in landscape and your app only draws in portrait, the whole app is sideways for that person forever.",
            wcagRef: "1.3.4",
            wcagTitle: "Orientation",
            testYourself: "Rotate your phone to landscape on every screen. Anything that refuses to rotate, or rotates and breaks, is the bug.",
            demo: .none
        ),
        LearnTopic(
            id: "pointer-cancellation",
            category: .motor,
            title: "Let People Take It Back",
            whatItIs: "Fire the action when the finger lifts, not the instant it lands, so a mis-tap can be slid away from.",
            whoItHurts: "People with tremors or spasms, people with a weak grip, and anyone tapping on a moving bus.",
            whyItMatters: "Acting on touch-up lets someone who lands on the wrong control drag off it and let go safely. SwiftUI Buttons do this already; hand-rolled gestures often do not.",
            wcagRef: "2.5.2",
            wcagTitle: "Pointer Cancellation",
            testYourself: "Press and hold a custom control, drag your finger off it, then lift. If the action still fired, you are triggering on touch-down.",
            demo: .none
        ),
        LearnTopic(
            id: "switch-scanning",
            category: .motor,
            title: "Design for Switch Scanning",
            whatItIs: "Switch users step through your screen one element at a time, so group related things and keep the number of stops low.",
            whoItHurts: "People who operate an iPhone with a single button, a head switch, or sip-and-puff, often people with cerebral palsy, ALS, or a spinal cord injury.",
            whyItMatters: "Every ungrouped element is another scan step and another wait. Forty flat items is technically operable and practically unusable.",
            wcagRef: "iOS platform",
            wcagTitle: "Switch Control",
            testYourself: "Settings, Accessibility, Switch Control. Set the full screen as a switch, then count the taps to reach your main action.",
            demo: .none
        )
    ]

    // MARK: Cognitive
    static let cognitive: [LearnTopic] = [
        LearnTopic(
            id: "plain-language",
            category: .cognitive,
            title: "Plain Language",
            whatItIs: "Write the way people actually talk, at a reading level everyone can follow.",
            whoItHurts: "People with cognitive disabilities, non-native speakers, and honestly — everyone who's tired.",
            whyItMatters: "Jargon and long sentences are a barrier. Cognitive accessibility is the most underserved area in all of a11y.",
            wcagRef: "3.1.5",
            wcagTitle: "Reading Level",
            testYourself: "Paste your onboarding copy into the Toolkit readability checker.",
            demo: .textReveal(
                before: "Utilize the aforementioned functionality to facilitate account authentication.",
                after: "Sign in to use this feature.",
                caption: "Same meaning, far less effort to read.")
        ),
        LearnTopic(
            id: "error-messages",
            category: .cognitive,
            title: "Helpful Error Messages",
            whatItIs: "When something goes wrong, say what happened and how to fix it.",
            whoItHurts: "Everyone — but especially people who anxiety-spiral or can't infer the fix.",
            whyItMatters: "\"Error 402\" helps no one. \"Your card expired — try another\" gets people unstuck.",
            wcagRef: "3.3.1",
            wcagTitle: "Error Identification",
            testYourself: "Trigger every error in your app. Does each one tell you what to do next?",
            demo: .textReveal(
                before: "Error: invalid input (code 402).",
                after: "That email is already registered. Try signing in instead.",
                caption: "Name the problem, offer the next step.")
        ),
        LearnTopic(
            id: "consistency",
            category: .cognitive,
            title: "Consistent Patterns",
            whatItIs: "Things that do the same job should look and sit in the same place everywhere.",
            whoItHurts: "People with memory or attention differences who rely on predictability.",
            whyItMatters: "Every inconsistency is a small relearning tax that adds up to exhaustion.",
            wcagRef: "3.2.3",
            wcagTitle: "Consistent Navigation",
            testYourself: "Is your back button (or primary action) in the same spot on every screen?",
            demo: .none
        ),
        LearnTopic(
            id: "redundant-entry",
            category: .cognitive,
            title: "Don't Make Me Remember",
            whatItIs: "Don't ask people to re-enter information they already gave you.",
            whoItHurts: "People with memory or attention differences — and everyone, honestly.",
            whyItMatters: "Re-typing your address on step 4 because step 2's data vanished is a needless burden. New in WCAG 2.2.",
            wcagRef: "3.3.7",
            wcagTitle: "Redundant Entry",
            testYourself: "In a multi-step form, auto-fill or offer previously entered info.",
            demo: .textReveal(
                before: "Re-enter your shipping address for billing.",
                after: "Billing same as shipping? ✓ (prefilled)",
                caption: "Reuse what they already told you.")
        ),
        LearnTopic(
            id: "predictable",
            category: .cognitive,
            title: "No Surprises",
            whatItIs: "Don't make big changes the moment someone taps or focuses a field.",
            whoItHurts: "People who are disoriented by context shifting under them.",
            whyItMatters: "Auto-submitting a form when the last field loses focus yanks control away from the user.",
            wcagRef: "3.2.2",
            wcagTitle: "On Input",
            testYourself: "Make sure changing a value never navigates or submits without a clear action.",
            demo: .none
        ),
        LearnTopic(
            id: "accessible-auth",
            category: .cognitive,
            title: "Accessible Authentication",
            whatItIs: "Don't require a memory or puzzle test just to log in.",
            whoItHurts: "People with cognitive disabilities who can't solve CAPTCHAs or recall codes.",
            whyItMatters: "Logging in shouldn't be a cognitive gauntlet. Allow paste, password managers, and Face ID. New in WCAG 2.2.",
            wcagRef: "3.3.8",
            wcagTitle: "Accessible Authentication (Minimum)",
            testYourself: "Does your login allow password-manager autofill and paste?",
            demo: .textReveal(
                before: "Solve this puzzle and re-type the 6-digit code from memory.",
                after: "Sign in with Face ID — or paste from your password manager.",
                caption: "Remove the memory test.")
        ),
        LearnTopic(
            id: "consistent-help",
            category: .cognitive,
            title: "Consistent Help",
            whatItIs: "Keep help and support in the same place across the app.",
            whoItHurts: "People who need help most and can't hunt for a moving target.",
            whyItMatters: "If \"Contact us\" jumps around, the people who rely on it are the ones most lost. New in WCAG 2.2.",
            wcagRef: "3.2.6",
            wcagTitle: "Consistent Help",
            testYourself: "Is your help/support entry point in the same location on every screen?",
            demo: .none
        ),
        LearnTopic(
            id: "labels-and-instructions",
            category: .cognitive,
            title: "Labels, Not Just Placeholders",
            whatItIs: "Every input needs a visible label and its rules stated up front, not only grey text sitting inside the box.",
            whoItHurts: "People with memory or attention differences, who lose the placeholder the moment they start typing.",
            whyItMatters: "Placeholder text is low contrast, it vanishes on the first keystroke, and it hides format rules until after you have got them wrong.",
            wcagRef: "3.3.2",
            wcagTitle: "Labels or Instructions",
            testYourself: "Fill in your longest form halfway, then screenshot it. Can you still tell what every field is asking for?",
            demo: .none
        ),
        LearnTopic(
            id: "input-purpose",
            category: .cognitive,
            title: "Let Autofill Do the Typing",
            whatItIs: "Tell iOS what each field is for so it can offer the right saved name, address, email, password, or one-time code.",
            whoItHurts: "People with dyslexia, people with limited dexterity, and people with memory difficulties, for whom typing an address by hand is slow and error-prone.",
            whyItMatters: "Setting textContentType turns a twelve-field checkout into a couple of taps. Leave it unset and everybody types everything, every time.",
            wcagRef: "1.3.5",
            wcagTitle: "Identify Input Purpose",
            testYourself: "Open your sign-up form with a saved contact card. Does the QuickType bar offer the right thing above the keyboard on each field?",
            demo: .none
        ),
        LearnTopic(
            id: "pause-stop-hide",
            category: .cognitive,
            title: "Let People Stop the Movement",
            whatItIs: "Anything that moves, blinks, or updates on its own for more than a few seconds needs a way to pause it.",
            whoItHurts: "People with ADHD or anxiety who cannot read past a looping carousel, and low-vision people using Zoom, who lose their place when content shifts.",
            whyItMatters: "Auto-rotating banners and live tickers pull attention off the task and never give it back. COGA guidance is blunt: let people switch the distraction off.",
            wcagRef: "2.2.2",
            wcagTitle: "Pause, Stop, Hide",
            testYourself: "List everything on your screens that moves without being touched. For each, can a person stop it without leaving the screen?",
            demo: .none
        ),
        LearnTopic(
            id: "language",
            category: .cognitive,
            title: "Say What Language This Is",
            whatItIs: "Mark the language of your content so the screen reader pronounces it with the right voice.",
            whoItHurts: "Blind users reading in a language other than their phone default, and bilingual users hitting a Spanish surname in English copy.",
            whyItMatters: "When the language is unset, VoiceOver reads French with an English voice and the words come out as noise. Hardcoded and mixed-language strings are where this breaks.",
            wcagRef: "3.1.1",
            wcagTitle: "Language of Page",
            testYourself: "Switch your phone to another language you read, turn on VoiceOver, and listen. Does anything come out as gibberish?",
            demo: .none
        )
    ]

    // MARK: Navigation
    static let navigation: [LearnTopic] = [
        LearnTopic(
            id: "focus-order",
            category: .navigation,
            title: "Logical Focus Order",
            whatItIs: "Screen readers should move through content in an order that makes sense.",
            whoItHurts: "Blind and low-vision people navigating with VoiceOver.",
            whyItMatters: "If focus jumps around randomly, the screen becomes a maze with the lights off.",
            wcagRef: "2.4.3",
            wcagTitle: "Focus Order",
            testYourself: "Turn on VoiceOver and swipe right repeatedly. Does the order feel natural?",
            demo: .none
        ),
        LearnTopic(
            id: "labels",
            category: .navigation,
            title: "Label Everything",
            whatItIs: "Every button and image a user acts on needs a meaningful name.",
            whoItHurts: "VoiceOver users, who hear \"button\" with no idea what it does.",
            whyItMatters: "An unlabeled icon button is invisible to screen readers — it might as well not exist.",
            wcagRef: "4.1.2",
            wcagTitle: "Name, Role, Value",
            testYourself: "VoiceOver every icon-only button. Does it announce something useful?",
            demo: .none
        ),
        LearnTopic(
            id: "headings",
            category: .navigation,
            title: "Real Headings",
            whatItIs: "Mark up section titles as headings so people can jump between them.",
            whoItHurts: "Screen-reader users who navigate by heading instead of reading everything.",
            whyItMatters: "Headings are the table of contents of a screen — without them there's no skipping ahead.",
            wcagRef: "2.4.6",
            wcagTitle: "Headings and Labels",
            testYourself: "Add `.accessibilityAddTraits(.isHeader)` to titles and test heading navigation.",
            demo: .none
        ),
        LearnTopic(
            id: "status-messages",
            category: .navigation,
            title: "Announce Status Changes",
            whatItIs: "Let screen readers hear updates — loading, success, errors — without moving focus.",
            whoItHurts: "VoiceOver users who never learn a toast or spinner appeared.",
            whyItMatters: "A silent \"Saved!\" toast means blind users don't know their action worked.",
            wcagRef: "4.1.3",
            wcagTitle: "Status Messages",
            testYourself: "Use `.accessibilityAddTraits(.updatesFrequently)` or an announcement for live updates.",
            demo: .none
        ),
        LearnTopic(
            id: "focus-visible",
            category: .navigation,
            title: "Visible Focus",
            whatItIs: "The currently focused element must be clearly, visibly highlighted.",
            whoItHurts: "Keyboard and switch users who lose track of where they are.",
            whyItMatters: "An invisible focus ring turns navigation into guesswork.",
            wcagRef: "2.4.7",
            wcagTitle: "Focus Visible",
            testYourself: "Tab through your app — can you always see what's focused?",
            demo: .none
        ),
        LearnTopic(
            id: "link-text",
            category: .navigation,
            title: "Meaningful Link Text",
            whatItIs: "Links and buttons should make sense out of context.",
            whoItHurts: "Screen-reader users who pull up a list of all links to navigate.",
            whyItMatters: "A screen full of \"Click here\" links read aloud tells the user nothing.",
            wcagRef: "2.4.4",
            wcagTitle: "Link Purpose (In Context)",
            testYourself: "Read your links out of context — does each one say where it goes?",
            demo: .textReveal(
                before: "To get the report, click here.",
                after: "Download the 2024 accessibility report (PDF).",
                caption: "The link text alone should say where it goes.")
        ),
        LearnTopic(
            id: "safe-motion",
            category: .navigation,
            title: "Motion & Vestibular Safety",
            whatItIs: "Offer a way to reduce large or parallax motion.",
            whoItHurts: "People with vestibular disorders, for whom big motion causes real nausea and dizziness.",
            whyItMatters: "A flashy parallax transition can physically sicken someone. Respect the Reduce Motion setting.",
            wcagRef: "2.3.3",
            wcagTitle: "Animation from Interactions",
            testYourself: "Turn on Reduce Motion — do your animations become gentle crossfades?",
            demo: .none
        )
    ,        LearnTopic(
            id: "label-in-name",
            category: .navigation,
            title: "Say What the Button Says",
            whatItIs: "A control accessibility label must contain the words a person can actually see on it.",
            whoItHurts: "Voice Control users who drive their phone by speaking button names out loud, including people with spinal cord injuries or severe RSI.",
            whyItMatters: "If the button reads Send but the label is submit_cta, saying Tap Send does nothing and the person is stranded on that screen.",
            wcagRef: "2.5.3",
            wcagTitle: "Label in Name",
            testYourself: "Settings, Accessibility, Voice Control. Say Tap plus the visible text of five buttons. Count how many respond.",
            demo: .none
        ),
        LearnTopic(
            id: "focus-not-obscured",
            category: .navigation,
            title: "Do Not Hide the Focused Control",
            whatItIs: "When something receives keyboard or switch focus, your own interface must not cover it up.",
            whoItHurts: "People using a Bluetooth keyboard, Switch Control, or Full Keyboard Access, who can tell focus moved but cannot see where.",
            whyItMatters: "Sticky headers, floating buttons, and the keyboard accessory bar routinely sit on top of the thing that just got focus. New in WCAG 2.2.",
            wcagRef: "2.4.11",
            wcagTitle: "Focus Not Obscured (Minimum)",
            testYourself: "Pair a keyboard, turn on Full Keyboard Access, and Tab down a long form. Does focus ever slide under your sticky header?",
            demo: .none
        ),
        LearnTopic(
            id: "voiceover-actions",
            category: .navigation,
            title: "Custom Actions and the Rotor",
            whatItIs: "Give VoiceOver users a short spoken menu of actions on an item instead of a row of tiny buttons to swipe past.",
            whoItHurts: "Blind VoiceOver users, who otherwise swipe through Edit, Share, Pin, and Delete on every single row of a long list.",
            whyItMatters: "Collapsing a row buttons into custom actions turns dozens of swipes into one. The rotor is also how blind people skim, and most apps never offer one.",
            wcagRef: "iOS platform",
            wcagTitle: "VoiceOver custom actions and rotor",
            testYourself: "Turn on VoiceOver, focus a list row with several buttons, then swipe up and down with one finger. Nothing offered means no custom actions.",
            demo: .none
        ),
        LearnTopic(
            id: "feedback-channels",
            category: .navigation,
            title: "Never Only a Buzz",
            whatItIs: "If a haptic tap or a sound is the only way someone learns what happened, some people learn nothing.",
            whoItHurts: "Deaf and hard of hearing users, people who keep the phone silent, people who switch System Haptics off, and anyone whose phone is face-down.",
            whyItMatters: "A success buzz with no visible confirmation and no announcement is a message sent into the void. Pair every haptic with something on screen.",
            wcagRef: "iOS platform",
            wcagTitle: "Haptics and sound as a sole channel",
            testYourself: "Settings, Sounds and Haptics, turn System Haptics off, and flip to silent. Complete a save. Do you still know it worked?",
            demo: .none
        ),
        LearnTopic(
            id: "screen-titles",
            category: .navigation,
            title: "Every Screen Says Where You Are",
            whatItIs: "Each screen needs a clear title that describes it and that VoiceOver reaches straight away.",
            whoItHurts: "VoiceOver users navigating a deep stack of pushed screens with no idea which one they just landed on.",
            whyItMatters: "In an app this is the navigation title, marked as a heading, announced first after a push. Without it, backing out three screens is guesswork.",
            wcagRef: "2.4.2",
            wcagTitle: "Page Titled",
            testYourself: "Turn on VoiceOver, push four screens deep, then swipe back one at a time. Does each screen announce its own name?",
            demo: .none
        )
    ]
}
