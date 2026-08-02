import SwiftUI

/// A single Learn entry. Plain-English first; the WCAG reference is intentionally
/// secondary (for people who want the spec). Each topic can carry an interactive
/// `demo` so the concept is *felt*, not just read.
///
/// Learn is where the depth lives. The Toolkit's quick reference is deliberately
/// three short lines per criterion, because a reference you have to read is not a
/// quick one. Everything that got cut from there landed in `mistake` and `fixIt`
/// here, next to the people it affects and the reason it matters.
struct LearnTopic: Identifiable, Hashable {
    let id: String                 // slug, also used for progress tracking
    let category: AccessibilityCategory
    let title: String
    let whatItIs: String           // one sentence, zero jargon
    let whoItHurts: String         // real humans, not abstract compliance
    let whyItMatters: String
    /// What this looks like when it is wrong. Recognition beats definition:
    /// most people can't recite 1.3.3 but they can spot "the button on the right".
    let mistake: String
    /// Concrete, iOS-specific steps. Two to four, each one thing you can do today.
    let fixIt: [String]
    let wcagRef: String            // e.g. "1.4.3"
    let wcagTitle: String          // e.g. "Contrast (Minimum)"
    let testYourself: String       // a quick action they can do right now
    let demo: LearnDemo

    /// Conformance level, looked up rather than stored, so the two tables can
    /// never drift apart. Nil for the iOS-platform topics with no criterion.
    var level: WCAGCriterion.Level? {
        WCAGReference.criterion(id: wcagRef)?.level
    }

    /// True when this is Apple-platform guidance rather than a WCAG criterion.
    var isPlatformGuidance: Bool { wcagRef == LearnContent.platformMarker }

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

/// Static Learn database. Covers every WCAG criterion in Ally's quick reference
/// plus the Apple-platform behaviours that have no criterion but break real apps.
enum LearnContent {
    /// One exact string for "this is platform guidance, not a criterion", so it
    /// can never be mistaken for a number someone invented.
    static let platformMarker = "iOS platform"

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
            whyItMatters: "Low-contrast text is the single most common accessibility failure on the web, and it quietly excludes millions.",
            mistake: "Grey-on-grey secondary text that looked refined on a colour-calibrated monitor and disappears outdoors.",
            fixIt: [
                "Body text needs 4.5:1. Text at 18pt regular or 14pt bold counts as large and needs 3:1.",
                "Measure it in the Toolkit rather than judging by eye. Both appearances, not just the one you design in.",
                "Never use pure opacity to make text quieter. Pick a lighter colour that still measures, so the ratio stays predictable."
            ],
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
            whoItHurts: "The roughly 1 in 12 men and 1 in 200 women with colour vision deficiency.",
            whyItMatters: "A red error and a green success look identical to someone with deuteranopia. They need text or icons too.",
            mistake: "A form where the only sign a field failed is that its border turned red.",
            fixIt: [
                "Add a second channel to every colour cue: an icon, a word, a shape, or a pattern.",
                "Say the state in the accessibility label as well, so it survives with the screen off.",
                "Screenshot the screen and run it through the Toolkit simulator before you ship the state."
            ],
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
            whoItHurts: "Anyone who bumps up their font size, a huge and growing group as people age.",
            whyItMatters: "If text is locked at a fixed size, the many users who enlarge system text simply cannot use your app comfortably.",
            mistake: "A .font(.system(size: 13)) that never moves, sitting inside a card with a fixed height.",
            fixIt: [
                "Use text styles, never fixed sizes. Font.system(.body) scales; Font.system(size: 13) does not.",
                "Add .fixedSize(horizontal: false, vertical: true) so wrapped text is allowed to be taller.",
                "Drop fixed frame heights on anything containing text. Let the container follow the content."
            ],
            wcagRef: "1.4.4",
            wcagTitle: "Resize Text",
            testYourself: "Set Larger Text to max in Settings → Accessibility. Does this screen still work?",
            demo: .textReveal(before: "Fixed 11pt caption text", after: "Scales with the reader", caption: "Left ignores Dynamic Type; right respects it.")
        ),
        LearnTopic(
            id: "non-text-contrast",
            category: .vision,
            title: "Non-Text Contrast",
            whatItIs: "Buttons, icons, and input borders need enough contrast too, not just text.",
            whoItHurts: "Low-vision users who can't find a button that blends into the background.",
            whyItMatters: "A pale outline-only button at 1.5:1 is invisible to many people. UI elements need at least 3:1.",
            mistake: "A chart where the only thing separating two series is two pastels of the same lightness.",
            fixIt: [
                "Check borders, toggles, focus rings, icons, and chart marks at 3:1, not just text.",
                "Measure a graphic against what is actually behind it. A pale arc on a pale track of the same hue can fail at 1.7:1.",
                "Where a fill has to stay soft, draw the meaningful part in a darkened version of the same hue."
            ],
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
            whyItMatters: "If your text is in fixed-height boxes, spacing overrides clip it, and the content is lost.",
            mistake: "A two-line card that shows one and a half lines the moment line height goes up.",
            fixIt: [
                "Never set an explicit height on a view that contains text.",
                "Prefer padding over frame height when you want a card to feel roomy.",
                "If you set lineSpacing, set it as an addition to the system value rather than replacing it."
            ],
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
            whoItHurts: "Deaf and hard-of-hearing users, and anyone watching with the sound off.",
            whyItMatters: "Without captions, video content is simply inaccessible to a large audience.",
            mistake: "Shipping raw auto-captions, which reliably mangle names, numbers, and every technical term in your product.",
            fixIt: [
                "Attach a real caption track to the asset so the system caption controls apply.",
                "Read the auto-generated pass back once and fix the product nouns. That is where it always goes wrong.",
                "Caption meaningful non-speech sound too, not just dialogue."
            ],
            wcagRef: "1.2.2",
            wcagTitle: "Captions (Prerecorded)",
            testYourself: "Mute every video in your app. Can you still follow it?",
            demo: .none
        ),
        LearnTopic(
            id: "audio-description",
            category: .vision,
            title: "Describe What Is Only Shown",
            whatItIs: "If your video shows something important without saying it, that has to be said somewhere.",
            whoItHurts: "Blind and low-vision users, who get the soundtrack and nothing else.",
            whyItMatters: "Product demos are the worst offenders. A voiceover that says tap here over an unnamed button is a video with no content in it for someone who cannot see the screen.",
            mistake: "A tutorial whose entire script is deictic: here, this, that one, up there.",
            fixIt: [
                "Write the visuals into the script first. A well-narrated video often needs no separate description track at all.",
                "Where the action is too dense for that, ship an audio-description track alongside the main audio.",
                "Name every control out loud instead of pointing at it."
            ],
            wcagRef: "1.2.5",
            wcagTitle: "Audio Description (Prerecorded)",
            testYourself: "Play your product video with the screen face-down. Could someone follow the steps?",
            demo: .none
        ),
        LearnTopic(
            id: "autoplay-audio",
            category: .vision,
            title: "Don't Start Sound on Its Own",
            whatItIs: "Audio that plays automatically for more than a few seconds needs a way to stop it.",
            whoItHurts: "VoiceOver users, whose speech gets buried under your soundtrack, and anyone whose phone just shouted in a quiet room.",
            whyItMatters: "A screen reader and an autoplaying video are competing for the same output. The person cannot turn yours down without turning theirs down too.",
            mistake: "A card that starts a video with sound as soon as it scrolls into view.",
            fixIt: [
                "Autoplay muted, always. Let the person choose to unmute.",
                "If sound has to start, put a visible pause control in reach on the same screen, not buried in a player overlay.",
                "Respect the silent switch and the system volume rather than forcing a level."
            ],
            wcagRef: "1.4.2",
            wcagTitle: "Audio Control",
            testYourself: "Turn on VoiceOver and open the screen with your loudest media. Can you still hear the announcements?",
            demo: .none
        ),
        LearnTopic(
            id: "images-of-text",
            category: .vision,
            title: "Avoid Images of Text",
            whatItIs: "Use real text, not pictures of text, wherever possible.",
            whoItHurts: "People who resize text or use screen readers. Images don't scale and don't get read.",
            whyItMatters: "Text baked into an image gets blurry when enlarged and is invisible to VoiceOver.",
            mistake: "An onboarding headline exported as a PNG so the letter spacing would be exactly right.",
            fixIt: [
                "Render type at runtime. Custom fonts, tracking, and gradients on text are all achievable in SwiftUI.",
                "Where a marketing image genuinely has to carry words, put those words in the accessibility label verbatim.",
                "Logos are the one real exception, and they still need a label."
            ],
            wcagRef: "1.4.5",
            wcagTitle: "Images of Text",
            testYourself: "Find any text living inside an image asset. Could it be real text instead?",
            demo: .none
        ),
        LearnTopic(
            id: "alt-text",
            category: .vision,
            title: "Alt Text That Earns Its Place",
            whatItIs: "Every image that carries meaning needs words that carry the same meaning.",
            whoItHurts: "Blind and low-vision users, and anyone on a slow connection where the image never arrives.",
            whyItMatters: "Alt text is not a caption and not a description of the pixels. It is the job the image was doing, written down. Get that wrong and the image is either noise or a hole in the page.",
            mistake: "Labelling a decorative divider IMG_4821, and labelling a meaningful chart chart.",
            fixIt: [
                "Ask what the image is for. If removing it would lose nothing, hide it with .accessibilityHidden(true).",
                "For informative images, write what it tells you, not what it looks like. A chart's label is its takeaway.",
                "Never start with image of or picture of. VoiceOver already says the role."
            ],
            wcagRef: "1.1.1",
            wcagTitle: "Non-text Content",
            testYourself: "Turn on VoiceOver and swipe through a content-heavy screen with your eyes shut. Count the images that told you nothing.",
            demo: .none
        ),
        LearnTopic(
            id: "seizure-safety",
            category: .vision,
            title: "Nothing Flashes Three Times",
            whatItIs: "No part of your interface may flash more than three times in any one second.",
            whoItHurts: "People with photosensitive epilepsy, for whom this is not discomfort but a seizure risk.",
            whyItMatters: "This is the only accessibility rule in the set that can physically harm someone. It is also the easiest to break by accident, usually with a loading state or a celebration effect nobody timed.",
            mistake: "A skeleton shimmer, a strobing success flash, or a fast camera-flash transition that nobody measured in frames.",
            fixIt: [
                "Count the frames. At 60fps, three flashes per second means no full light-to-dark cycle shorter than about 20 frames.",
                "Keep flashing areas small and low contrast. Large, high-contrast, red flashes are the dangerous combination.",
                "Gate anything energetic behind Reduce Motion, and make the reduced version genuinely still."
            ],
            wcagRef: "2.3.1",
            wcagTitle: "Three Flashes or Below Threshold",
            testYourself: "Screen-record your busiest loading and success states, then step through frame by frame. Anything cycling faster than three times a second is a bug.",
            demo: .none
        ),
        LearnTopic(
            id: "contrast-settings",
            category: .vision,
            title: "Respect Increase Contrast",
            whatItIs: "iOS lets people ask for stronger contrast and solid backgrounds, and your app has to actually change when they do.",
            whoItHurts: "Low-vision users, people with cataracts, and anyone with glare sensitivity, who turn these on system wide.",
            whyItMatters: "Blur and translucency look great in a design review and dissolve in real use. When these settings are on, go fully opaque and stop using blur to separate layers.",
            mistake: "A frosted-glass tab bar that stays frosted after someone asks for solid backgrounds.",
            fixIt: [
                "Read @Environment(\\.colorSchemeContrast) and swap tinted fills for solid ones when it is .increased.",
                "Read UIAccessibility.isReduceTransparencyEnabled and replace every material with an opaque surface.",
                "Strengthen hairline borders in the same pass. A 0.5pt border at 1.4:1 is the first thing to vanish."
            ],
            wcagRef: "iOS platform",
            wcagTitle: "Increase Contrast and Reduce Transparency",
            testYourself: "Settings, Accessibility, Display and Text Size. Turn on Increase Contrast and Reduce Transparency, then reopen every screen that uses a blur.",
            demo: .none
        ),
        LearnTopic(
            id: "smart-invert",
            category: .vision,
            title: "Survive Smart Invert",
            whatItIs: "Smart Invert flips your colours but is supposed to leave photos and media alone, and it only knows to do that if you tell it.",
            whoItHurts: "Low-vision users and people with light sensitivity who run inverted colours all day, long before your app offered a dark mode.",
            whyItMatters: "Without one modifier, every photograph in your app becomes a negative. Faces go green, product shots become unreadable, and the person has no idea it is your bug rather than theirs.",
            mistake: "Assuming shipping dark mode means inverted colours are handled. They are separate systems and people use both.",
            fixIt: [
                "Add .accessibilityIgnoresInvertColors(true) to photos, avatars, video, and any already-dark artwork.",
                "Do not apply it to your whole UI. Inverting the chrome is the point.",
                "Check that text drawn over an image still passes contrast once the image is left alone and the background is not."
            ],
            wcagRef: "iOS platform",
            wcagTitle: "Smart Invert Colors",
            testYourself: "Settings, Accessibility, Display and Text Size, Smart Invert. Open your most image-heavy screen.",
            demo: .none
        ),
        LearnTopic(
            id: "mono-audio",
            category: .vision,
            title: "Never Split Meaning Across Two Ears",
            whatItIs: "Don't put different information in the left and right channels, and never rely on stereo position to mean something.",
            whoItHurts: "People who are deaf in one ear, people using a single hearing aid, and anyone wearing one AirPod on a call.",
            whyItMatters: "Unilateral hearing loss is common and invisible. If a warning tone only plays on the right, a meaningful share of your users will never hear it.",
            mistake: "A game or a call app that pans alerts, or an interface sound that only exists in one channel.",
            fixIt: [
                "Keep interface audio mono, or duplicate it across both channels.",
                "Never make stereo position the only carrier of information. Pair it with something visible.",
                "Respect the system Mono Audio setting rather than mixing your own down."
            ],
            wcagRef: "iOS platform",
            wcagTitle: "Mono Audio and hearing",
            testYourself: "Wear one earbud, left then right, and use the app for two minutes. Did you miss anything?",
            demo: .none
        ),
        LearnTopic(
            id: "reflow-at-ax-sizes",
            category: .vision,
            title: "Survive the Biggest Text Size",
            whatItIs: "Your layout has to reflow into one readable column at the largest accessibility text sizes, with no sideways scrolling.",
            whoItHurts: "People who run their phone at AX3 or AX5 every day, often older users and people with low vision.",
            whyItMatters: "Supporting Dynamic Type is not the same as surviving it. Side-by-side buttons and fixed-height cards break long before AX5.",
            mistake: "Two buttons in an HStack that each get 40pt wide and clip to Sa… and Can… at AX5.",
            fixIt: [
                "Use ViewThatFits, or read @Environment(\\.dynamicTypeSize) and switch an HStack to a VStack past .accessibility1.",
                "Let long labels wrap rather than reaching for minimumScaleFactor, which just makes text small again.",
                "Test at AX5 as a matter of routine, not as a final check. Most layouts break somewhere between AX1 and AX3."
            ],
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
            mistake: "A 17pt SF Symbol used as a button, where the glyph is the whole hit area.",
            fixIt: [
                "Give the button a .frame(minWidth: 44, minHeight: 44) and a .contentShape(Rectangle()) so the padding is tappable too.",
                "Grow the hit area rather than the glyph. A small icon inside a 44pt target is fine.",
                "Leave real space between adjacent targets. Two 44pt buttons touching is still a mis-tap waiting to happen."
            ],
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
            mistake: "Swipe-to-delete with no edit mode, no context menu, and no VoiceOver custom action.",
            fixIt: [
                "For every gesture, list the same action reachable by a single tap somewhere on screen.",
                "Add .accessibilityAction(named:) so VoiceOver users get it in the actions rotor.",
                "A long-press context menu counts as an alternative only if it is discoverable. Say so somewhere."
            ],
            wcagRef: "2.5.1",
            wcagTitle: "Pointer Gestures",
            testYourself: "List every action in your app that requires a swipe or pinch. Does each have a button too?",
            demo: .none
        ),
        LearnTopic(
            id: "keyboard",
            category: .motor,
            title: "Keyboard & Switch Access",
            whatItIs: "Everything must work without a touchscreen, via keyboard or switch control.",
            whoItHurts: "People who navigate with a switch, keyboard, or other assistive input.",
            whyItMatters: "If an action is touch-only, switch-control users are locked out of it entirely.",
            mistake: "A custom control built on a tap gesture rather than a Button, so it is invisible to every non-touch input.",
            fixIt: [
                "Build interactive things out of Button, Toggle, and the other real controls. A .onTapGesture on a shape is not focusable.",
                "Turn on Full Keyboard Access and Tab through the whole app. Anything you cannot reach is unreachable.",
                "Give the primary action a keyboard shortcut where it makes sense, with .keyboardShortcut."
            ],
            wcagRef: "2.1.1",
            wcagTitle: "Keyboard",
            testYourself: "Turn on Full Keyboard Access and try to reach every control with Tab.",
            demo: .none
        ),
        LearnTopic(
            id: "keyboard-trap",
            category: .motor,
            title: "Never Trap the Keyboard",
            whatItIs: "Focus has to be able to leave every component it can enter.",
            whoItHurts: "Keyboard and Switch Control users, who have no way to tap somewhere else to escape.",
            whyItMatters: "A touch user gets out of a stuck component by tapping elsewhere. Someone driving the phone with a single switch has exactly one move available, and if that move does not work the app is over for them.",
            mistake: "A sheet, an embedded web view, or a text field with a custom accessory bar that swallows Tab and never gives it back.",
            fixIt: [
                "Tab into every sheet, popover, web view, and multi-line field, then Tab back out. Both directions.",
                "Give every modal a keyboard-reachable dismiss, not just a drag indicator.",
                "Be careful with @FocusState loops. Programmatically restoring focus on every change can pin someone in one field."
            ],
            wcagRef: "2.1.2",
            wcagTitle: "No Keyboard Trap",
            testYourself: "Pair a keyboard, open your most complex sheet, and try to Tab all the way out of it without touching the screen.",
            demo: .none
        ),
        LearnTopic(
            id: "character-shortcuts",
            category: .motor,
            title: "Single-Key Shortcuts Need an Off Switch",
            whatItIs: "If a bare letter key triggers an action, people must be able to turn it off, remap it, or scope it to a focused control.",
            whoItHurts: "Speech-input users, whose dictation lands stray characters, and people with tremors who hit neighbouring keys.",
            whyItMatters: "Someone using Voice Control is effectively typing constantly. Every unmodified letter shortcut is a landmine that fires an action they did not ask for.",
            mistake: "Adding r for reply and d for delete on an iPad app because it felt fast on a Mac.",
            fixIt: [
                "Require a modifier. .keyboardShortcut(\"d\", modifiers: .command) is safe; a bare \"d\" is not.",
                "If a bare key really is worth it, only listen while the relevant control has focus.",
                "Offer a setting to switch single-key shortcuts off entirely."
            ],
            wcagRef: "2.1.4",
            wcagTitle: "Character Key Shortcuts",
            testYourself: "Pair a keyboard, put focus somewhere harmless, and type a sentence. Did anything happen that should not have?",
            demo: .none
        ),
        LearnTopic(
            id: "dragging",
            category: .motor,
            title: "Dragging Alternatives",
            whatItIs: "Anything you drag should also be doable without dragging.",
            whoItHurts: "People who can't hold a precise press-and-drag, whether from tremor, one-handed use, or a stylus.",
            whyItMatters: "Reorder-by-drag with no alternative means some users can never reorder. New in WCAG 2.2.",
            mistake: "A drag handle as the only affordance for reordering a list.",
            fixIt: [
                "Add move up and move down buttons, or a move to… menu, next to the handle.",
                "Sliders need a stepper or a text field alongside them, not just the thumb.",
                "Expose the same moves as VoiceOver custom actions so they are one swipe away."
            ],
            wcagRef: "2.5.7",
            wcagTitle: "Dragging Movements",
            testYourself: "For each drag interaction, add tap-based buttons such as move up and move down.",
            demo: .none
        ),
        LearnTopic(
            id: "timeouts",
            category: .motor,
            title: "Enough Time",
            whatItIs: "Don't force people to act within a tight time limit.",
            whoItHurts: "Anyone who reads or moves slowly, or gets interrupted mid-task.",
            whyItMatters: "Auto-dismissing dialogs and countdowns punish people for needing more time.",
            mistake: "Putting the only Undo inside a toast that disappears after three seconds.",
            fixIt: [
                "Warn before a session expires and offer a one-tap extension.",
                "Never make a disappearing element the only route to an action. Keep a permanent one too.",
                "Where a limit is essential, say how long it is up front rather than surprising people with it."
            ],
            wcagRef: "2.2.1",
            wcagTitle: "Timing Adjustable",
            testYourself: "Find any countdown or auto-dismiss. Can it be paused or extended?",
            demo: .none
        ),
        LearnTopic(
            id: "motion-actuation",
            category: .motor,
            title: "Motion Isn't the Only Way",
            whatItIs: "Features triggered by moving the device need a regular control too.",
            whoItHurts: "People who can't shake, tilt, or move their phone freely.",
            whyItMatters: "Shake to undo with no button is unusable for someone whose phone is mounted to a chair.",
            mistake: "Relying on the system shake-to-undo gesture for a destructive action with no visible alternative.",
            fixIt: [
                "Put the same action on a visible control, on the same screen.",
                "Let people turn the motion trigger off, because false positives on a bumpy bus are their own problem.",
                "Do not use device motion for anything a person cannot also do standing still."
            ],
            wcagRef: "2.5.4",
            wcagTitle: "Motion Actuation",
            testYourself: "Does every shake or tilt gesture have an on-screen equivalent?",
            demo: .none
        ),
        LearnTopic(
            id: "orientation",
            category: .motor,
            title: "Work in Both Orientations",
            whatItIs: "Do not lock your app to portrait unless the content genuinely requires one orientation.",
            whoItHurts: "People whose iPhone is clamped to a wheelchair, a bed mount, or a desk arm in a position they cannot rotate.",
            whyItMatters: "If the phone is mounted in landscape and your app only draws in portrait, the whole app is sideways for that person forever.",
            mistake: "Locking portrait in the target settings early on and never revisiting it.",
            fixIt: [
                "Remove the orientation lock, then fix whatever it was hiding.",
                "Reuse the Dynamic Type reflow work. A layout that survives AX5 usually survives landscape.",
                "Keep the safe area in mind. Landscape on a notched device eats the leading edge."
            ],
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
            mistake: "A custom control using DragGesture(minimumDistance: 0).onChanged to fire immediately.",
            fixIt: [
                "Use Button. It already commits on touch-up inside, and cancels if you slide away.",
                "Where you must hand-roll, act in onEnded and check the finger is still inside the bounds.",
                "The exception is anything that must be instant, like a piano key. Those should be undoable instead."
            ],
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
            mistake: "A card whose title, subtitle, badge, and chevron are four separate stops instead of one.",
            fixIt: [
                "Combine card contents with .accessibilityElement(children: .combine) so a card is one stop.",
                "Put the most common action first in the scan order, not last.",
                "Count the stops between opening a screen and doing the main thing. Anything over about six needs rethinking."
            ],
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
            whoItHurts: "People with cognitive disabilities, non-native speakers, and honestly, everyone who's tired.",
            whyItMatters: "Jargon and long sentences are a barrier. Cognitive accessibility is the most underserved area in all of accessibility.",
            mistake: "Writing for the legal team and shipping it to the user.",
            fixIt: [
                "Cut sentence length before you cut vocabulary. Two short sentences beat one clever one.",
                "Use the words your users use, not your internal nouns. Nobody has ever wanted to provision an entity.",
                "Run your densest screen through the Toolkit readability tool and aim for grade 8 or below."
            ],
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
            whoItHurts: "Everyone, but especially people who anxiety-spiral or can't infer the fix.",
            whyItMatters: "Error 402 helps no one. Your card expired, try another gets people unstuck.",
            mistake: "A single banner reading Something went wrong for nine different failure modes.",
            fixIt: [
                "Name the field that failed, in text, next to that field. Not only in a banner at the top.",
                "Never rely on a red border alone. That is a colour-only cue.",
                "Announce the error so VoiceOver hears it, and move focus only if the person has nothing in progress."
            ],
            wcagRef: "3.3.1",
            wcagTitle: "Error Identification",
            testYourself: "Trigger every error in your app. Does each one tell you what to do next?",
            demo: .textReveal(
                before: "Error: invalid input (code 402).",
                after: "That email is already registered. Try signing in instead.",
                caption: "Name the problem, offer the next step.")
        ),
        LearnTopic(
            id: "error-suggestion",
            category: .cognitive,
            title: "Suggest the Fix, Not Just the Fault",
            whatItIs: "If you know what a valid value looks like, say so instead of only saying no.",
            whoItHurts: "People with cognitive or learning disabilities, and anyone who cannot guess the format you had in mind.",
            whyItMatters: "Identifying an error and suggesting a fix are two different requirements. Invalid date tells someone they failed. Use DD/MM/YYYY, for example 04/09/1991 tells them how to succeed.",
            mistake: "Validation that knows exactly which rule failed and reports only that something is invalid.",
            fixIt: [
                "Turn every validation rule into a sentence a person can act on, including an example.",
                "Where you can infer the intent, offer it: did you mean gmail.com?",
                "Show format requirements before submission, not only after failure."
            ],
            wcagRef: "3.3.3",
            wcagTitle: "Error Suggestion",
            testYourself: "Fill every form in your app wrong on purpose. Count how many messages tell you what right looks like.",
            demo: .textReveal(
                before: "Invalid date.",
                after: "Use DD/MM/YYYY, for example 04/09/1991.",
                caption: "Show the shape of a correct answer.")
        ),
        LearnTopic(
            id: "error-prevention",
            category: .cognitive,
            title: "Let People Check Before It's Final",
            whatItIs: "Anything involving money, a legal commitment, or deleting data needs a way back.",
            whoItHurts: "Everyone, and disproportionately people who mis-tap, people who are rushing, and people who cannot easily undo a mistake later.",
            whyItMatters: "Reversible, checkable, or confirmed. You need one of the three, and confirmation dialogs are the weakest of them because people learn to dismiss them without reading.",
            mistake: "A one-tap Delete Account that skips straight to done, with a confirm sheet that says Are you sure? and nothing else.",
            fixIt: [
                "Prefer reversible. An undo window beats a confirmation dialog every time.",
                "Where you confirm, state the consequence in the button: Delete 42 photos, not OK.",
                "Show a review step for anything financial, with the actual numbers on screen."
            ],
            wcagRef: "3.3.4",
            wcagTitle: "Error Prevention (Legal, Financial, Data)",
            testYourself: "List every action in your app that spends money or destroys data. For each one, name which of reversible, checkable, or confirmed it is.",
            demo: .none
        ),
        LearnTopic(
            id: "consistency",
            category: .cognitive,
            title: "Consistent Patterns",
            whatItIs: "Things that do the same job should look and sit in the same place everywhere.",
            whoItHurts: "People with memory or attention differences who rely on predictability.",
            whyItMatters: "Every inconsistency is a small relearning tax that adds up to exhaustion.",
            mistake: "Save on the trailing side of one screen and the leading side of the next.",
            fixIt: [
                "Pick one home for the primary action and never move it.",
                "Reuse one component for one job. Two card styles doing the same thing is an inconsistency.",
                "Keep the same word for the same concept across the whole app."
            ],
            wcagRef: "3.2.3",
            wcagTitle: "Consistent Navigation",
            testYourself: "Is your back button, or primary action, in the same spot on every screen?",
            demo: .none
        ),
        LearnTopic(
            id: "sensory-characteristics",
            category: .cognitive,
            title: "Don't Say “the Button on the Right”",
            whatItIs: "Instructions can't depend on shape, size, position, colour, or sound alone.",
            whoItHurts: "Blind users, who have no right; low-vision users at high zoom, for whom nothing is where you think; and colour-blind users, for whom the green one means nothing.",
            whyItMatters: "Position words are the most common of these and the easiest to fix. At AX5 or in landscape, the button on the right is often underneath.",
            mistake: "Help text reading tap the round icon at the bottom, or press the green button to continue.",
            fixIt: [
                "Name the control first, then add position as extra: tap Continue, at the bottom of the screen.",
                "Never use only a colour word. Green, red, and highlighted are not identifiers.",
                "Check your empty states and onboarding copy first. That is where this lives."
            ],
            wcagRef: "1.3.3",
            wcagTitle: "Sensory Characteristics",
            testYourself: "Search your strings for right, left, above, below, round, and the colour words. Every hit is a candidate.",
            demo: .textReveal(
                before: "Tap the round green button on the right.",
                after: "Tap Continue, the green button at the bottom right.",
                caption: "Name it first. Position is a bonus, not the identifier.")
        ),
        LearnTopic(
            id: "redundant-entry",
            category: .cognitive,
            title: "Don't Make Me Remember",
            whatItIs: "Don't ask people to re-enter information they already gave you.",
            whoItHurts: "People with memory or attention differences, and everyone, honestly.",
            whyItMatters: "Re-typing your address on step 4 because step 2's data vanished is a needless burden. New in WCAG 2.2.",
            mistake: "A multi-step form that clears itself when someone taps back to check something.",
            fixIt: [
                "Persist in-progress answers across navigation, backgrounding, and process death.",
                "Offer a same as above toggle rather than a second empty set of fields.",
                "Where you must ask again for a real reason, such as confirming a password, say why."
            ],
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
            mistake: "A picker that navigates on selection, so scrolling past an option takes you somewhere.",
            fixIt: [
                "Require an explicit action to commit. Selecting is not submitting.",
                "Never open a sheet, push a screen, or start a network call purely because focus arrived.",
                "If a change does reshape the screen, announce it rather than letting it happen silently."
            ],
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
            mistake: "Blocking paste in the password field for security, which only blocks password managers.",
            fixIt: [
                "Never disable paste. It is the single most common way this criterion fails.",
                "Set textContentType to .password, .newPassword, and .oneTimeCode so the system can fill them.",
                "Offer Face ID or a passkey as a first-class route, not as a secondary option."
            ],
            wcagRef: "3.3.8",
            wcagTitle: "Accessible Authentication (Minimum)",
            testYourself: "Does your login allow password-manager autofill and paste?",
            demo: .textReveal(
                before: "Solve this puzzle and re-type the 6-digit code from memory.",
                after: "Sign in with Face ID, or paste from your password manager.",
                caption: "Remove the memory test.")
        ),
        LearnTopic(
            id: "consistent-help",
            category: .cognitive,
            title: "Consistent Help",
            whatItIs: "Keep help and support in the same place across the app.",
            whoItHurts: "People who need help most and can't hunt for a moving target.",
            whyItMatters: "If Contact us jumps around, the people who rely on it are the ones most lost. New in WCAG 2.2.",
            mistake: "Help in the settings menu on one screen, in a floating bubble on another, and absent from a third.",
            fixIt: [
                "Choose one location for the help entry point and repeat it on every screen that has one.",
                "Same order, same wording, same icon. Relative position is what the criterion asks for.",
                "If a screen has no help, that is fine. Moving it is what breaks people."
            ],
            wcagRef: "3.2.6",
            wcagTitle: "Consistent Help",
            testYourself: "Is your help or support entry point in the same location on every screen?",
            demo: .none
        ),
        LearnTopic(
            id: "labels-and-instructions",
            category: .cognitive,
            title: "Labels, Not Just Placeholders",
            whatItIs: "Every input needs a visible label and its rules stated up front, not only grey text sitting inside the box.",
            whoItHurts: "People with memory or attention differences, who lose the placeholder the moment they start typing.",
            whyItMatters: "Placeholder text is low contrast, it vanishes on the first keystroke, and it hides format rules until after you have got them wrong.",
            mistake: "A beautiful minimal form where every field is an unlabelled box with grey hint text.",
            fixIt: [
                "Put a persistent visible label above or beside the field. The placeholder can then show an example.",
                "State the rules before submission: at least 8 characters, one number.",
                "Mark required fields in words, not only with an asterisk."
            ],
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
            mistake: "A sign-up form where the keyboard is a plain QWERTY on every field, including email and the SMS code.",
            fixIt: [
                "Set .textContentType on every field. .emailAddress, .name, .streetAddressLine1, .oneTimeCode, and friends.",
                "Set .keyboardType to match, so an email field opens with an @ key.",
                "Test with a saved contact card and a real SMS code. The QuickType bar is the proof."
            ],
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
            mistake: "A hero carousel that advances every four seconds with no pause control anywhere.",
            fixIt: [
                "Give any auto-advancing element a visible pause control on the same screen.",
                "Stop the rotation permanently once someone interacts with it. Resuming is its own annoyance.",
                "Honour Reduce Motion by not auto-advancing at all."
            ],
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
            mistake: "Server-supplied content in a second language rendered into a view the system believes is English.",
            fixIt: [
                "Use AttributedString with .languageIdentifier on any run that is in another language.",
                "Localise properly rather than hardcoding strings. The language comes free with the bundle.",
                "Watch out for user-generated content and product names, which are the usual offenders."
            ],
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
            mistake: "A ZStack where a decorative overlay comes first in the tree, so VoiceOver starts on nothing.",
            fixIt: [
                "Match the visual reading order. Where the tree cannot, use .accessibilitySortPriority.",
                "Hide decorative layers with .accessibilityHidden(true) so they never take a turn.",
                "After a sheet or a push, check where focus lands. Silence usually means it landed on a container."
            ],
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
            whoItHurts: "VoiceOver users, who hear button with no idea what it does.",
            whyItMatters: "An unlabeled icon button is invisible to screen readers. It might as well not exist.",
            mistake: "An icon-only toolbar where every item announces its SF Symbol name, or nothing at all.",
            fixIt: [
                "Give every icon-only control an .accessibilityLabel that says what it does, not what it looks like.",
                "Custom controls need a trait too. .accessibilityAddTraits(.isButton) is what makes it announce as a button.",
                "Anything with a state needs a value: .accessibilityValue(isOn ? \"On\" : \"Off\")."
            ],
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
            whyItMatters: "Headings are the table of contents of a screen. Without them there's no skipping ahead.",
            mistake: "Section titles that are visually obvious and programmatically indistinguishable from body text.",
            fixIt: [
                "Add .accessibilityAddTraits(.isHeader) to every section title.",
                "Write headings someone would actually search for. Details is not a heading.",
                "Keep the visual hierarchy and the marked hierarchy in agreement."
            ],
            wcagRef: "2.4.6",
            wcagTitle: "Headings and Labels",
            testYourself: "Add .accessibilityAddTraits(.isHeader) to titles and test heading navigation with the rotor.",
            demo: .none
        ),
        LearnTopic(
            id: "info-relationships",
            category: .navigation,
            title: "Structure That Code Can See",
            whatItIs: "Any structure you communicate visually has to exist programmatically too.",
            whoItHurts: "Screen-reader users, for whom your layout does not exist. Only the tree does.",
            whyItMatters: "Grouping, hierarchy, and association are all invisible to assistive tech unless you say them out loud. A label sitting next to a field is not attached to it just because they are close.",
            mistake: "A form where labels and fields are separate elements, so VoiceOver reads four labels and then four unlabelled text fields.",
            fixIt: [
                "Combine a label and its control into one element, or set the control's label from the visible text.",
                "Group related content with .accessibilityElement(children: .combine) so relationships survive.",
                "Mark headings, and use real lists and tables rather than styling a VStack to look like one."
            ],
            wcagRef: "1.3.1",
            wcagTitle: "Info and Relationships",
            testYourself: "Turn on VoiceOver and swipe through your longest form. Does every field announce what it is for?",
            demo: .none
        ),
        LearnTopic(
            id: "bypass-blocks",
            category: .navigation,
            title: "Let People Skip the Repeated Part",
            whatItIs: "Give people a way past the chrome that appears on every screen.",
            whoItHurts: "VoiceOver and Switch Control users, who otherwise traverse your header, tabs, and filters before reaching the content, every single time.",
            whyItMatters: "On the web this is a skip link. In an app it is headings, containers, and the rotor. Without them, a long screen means dozens of swipes before the first piece of real content.",
            mistake: "A screen where the toolbar, the search field, and eight filter chips are all individual stops ahead of the list.",
            fixIt: [
                "Mark real headings so the rotor's heading mode can jump between sections.",
                "Group chrome into containers with .accessibilityElement(children: .contain) so it can be skipped as a unit.",
                "Consider .accessibilityRotor to publish a custom rotor for the sections that matter."
            ],
            wcagRef: "2.4.1",
            wcagTitle: "Bypass Blocks",
            testYourself: "Turn on VoiceOver and count the swipes from the top of a busy screen to its first real item.",
            demo: .none
        ),
        LearnTopic(
            id: "status-messages",
            category: .navigation,
            title: "Announce Status Changes",
            whatItIs: "Let screen readers hear updates such as loading, success, and errors, without moving focus.",
            whoItHurts: "VoiceOver users who never learn a toast or spinner appeared.",
            whyItMatters: "A silent Saved toast means blind users don't know their action worked.",
            mistake: "A spinner that appears, spins, and disappears with no announcement at either end.",
            fixIt: [
                "Post AccessibilityNotification.Announcement when something finishes or fails.",
                "Do not move focus to the message. That interrupts whatever the person was doing.",
                "Keep it short. The announcement is competing with the rest of the screen for attention."
            ],
            wcagRef: "4.1.3",
            wcagTitle: "Status Messages",
            testYourself: "Turn on VoiceOver and trigger a save, a failure, and a long load. Did you hear all three?",
            demo: .none
        ),
        LearnTopic(
            id: "focus-visible",
            category: .navigation,
            title: "Visible Focus",
            whatItIs: "The currently focused element must be clearly, visibly highlighted.",
            whoItHurts: "Keyboard and switch users who lose track of where they are.",
            whyItMatters: "An invisible focus ring turns navigation into guesswork.",
            mistake: "Suppressing the system focus ring on a custom control because it did not match the design.",
            fixIt: [
                "Keep the system ring unless you are drawing something stronger.",
                "A custom focus state needs 3:1 against both the focused element and what surrounds it.",
                "Never rely on a colour change alone. Add a ring, an outline, or a shift in weight."
            ],
            wcagRef: "2.4.7",
            wcagTitle: "Focus Visible",
            testYourself: "Tab through your app. Can you always see what's focused?",
            demo: .none
        ),
        LearnTopic(
            id: "link-text",
            category: .navigation,
            title: "Meaningful Link Text",
            whatItIs: "Links and buttons should make sense out of context.",
            whoItHurts: "Screen-reader users who pull up a list of all links to navigate.",
            whyItMatters: "A screen full of click here links read aloud tells the user nothing.",
            mistake: "Six Learn more links on one page, each going somewhere different.",
            fixIt: [
                "Put the destination in the link text: Read the 2024 report.",
                "Where the visible text has to stay short, extend it in the accessibility label.",
                "Say the format and size for anything that is not a normal page: PDF, 2 MB."
            ],
            wcagRef: "2.4.4",
            wcagTitle: "Link Purpose (In Context)",
            testYourself: "Read your links out of context. Does each one say where it goes?",
            demo: .textReveal(
                before: "To get the report, click here.",
                after: "Download the 2024 accessibility report (PDF).",
                caption: "The link text alone should say where it goes.")
        ),
        LearnTopic(
            id: "multiple-ways",
            category: .navigation,
            title: "Multiple Ways to Find Things",
            whatItIs: "Anything worth finding should be reachable by more than one route.",
            whoItHurts: "People with memory differences who cannot retrace a menu path, and people who simply think in a different order than your information architecture does.",
            whyItMatters: "Browse and search are different mental modes, and different people live in different ones. Offering only a hierarchy means everyone has to learn yours.",
            mistake: "Content buried three taps into a category tree with no search anywhere.",
            fixIt: [
                "Offer search alongside browse, not instead of it.",
                "Cross-link related content so there is a lateral route as well as a top-down one.",
                "Support Spotlight and app shortcuts, so the route can start outside your app."
            ],
            wcagRef: "2.4.5",
            wcagTitle: "Multiple Ways",
            testYourself: "Pick a screen deep in your app. Name three different ways someone could get there.",
            demo: .none
        ),
        LearnTopic(
            id: "safe-motion",
            category: .navigation,
            title: "Motion & Vestibular Safety",
            whatItIs: "Offer a way to reduce large or parallax motion.",
            whoItHurts: "People with vestibular disorders, for whom big motion causes real nausea and dizziness.",
            whyItMatters: "A flashy parallax transition can physically sicken someone. Respect the Reduce Motion setting.",
            mistake: "Checking Reduce Motion in one place and forgetting the six decorative animations elsewhere.",
            fixIt: [
                "Read @Environment(\\.accessibilityReduceMotion) and swap large motion for a crossfade.",
                "Reduced does not mean removed. A still frame should be composed, not frozen at frame zero.",
                "The dangerous ones are parallax, zoom, spin, and anything crossing a large part of the screen."
            ],
            wcagRef: "2.3.3",
            wcagTitle: "Animation from Interactions",
            testYourself: "Turn on Reduce Motion. Do your animations become gentle crossfades?",
            demo: .none
        ),
        LearnTopic(
            id: "label-in-name",
            category: .navigation,
            title: "Say What the Button Says",
            whatItIs: "A control accessibility label must contain the words a person can actually see on it.",
            whoItHurts: "Voice Control users who drive their phone by speaking button names out loud, including people with spinal cord injuries or severe RSI.",
            whyItMatters: "If the button reads Send but the label is submit_cta, saying Tap Send does nothing and the person is stranded on that screen.",
            mistake: "Overriding a perfectly good visible label with a more descriptive one that no longer contains the visible words.",
            fixIt: [
                "Start the accessibility label with the visible text, then add detail after it.",
                "Never replace the visible text with internal naming or a localisation key.",
                "Watch out for icon-plus-text buttons where the label describes only the icon."
            ],
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
            mistake: "A floating action button or a custom tab bar drawn over a scroll view with no matching bottom inset.",
            fixIt: [
                "Add bottom content padding equal to the height of anything floating over the scroll view.",
                "Hide overlays entirely on pushed screens, the way the system hides a tab bar.",
                "Test with the keyboard up. The accessory bar is the most common offender."
            ],
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
            whyItMatters: "Collapsing a row's buttons into custom actions turns dozens of swipes into one. The rotor is also how blind people skim, and most apps never offer one.",
            mistake: "A list row exposing five separate buttons, multiplied by fifty rows.",
            fixIt: [
                "Combine the row into one element, then attach .accessibilityAction(named:) for each action.",
                "Name the actions as verbs. Delete, not trash icon.",
                "Publish a custom rotor with .accessibilityRotor for long lists with a natural grouping."
            ],
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
            mistake: "A save that fires a success haptic and changes nothing visible.",
            fixIt: [
                "Every haptic gets a visible partner: a state change, a badge, a message.",
                "Add an announcement so VoiceOver users get it too. Haptics are not universally felt.",
                "Never use sound alone for an alert. Someone is always on silent."
            ],
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
            mistake: "Hiding the navigation bar for a custom header and never giving the screen a name at all.",
            fixIt: [
                "Set .navigationTitle on every pushed screen, even when the bar is visually hidden.",
                "Where you draw a custom header, mark it with .accessibilityAddTraits(.isHeader).",
                "Make the title specific. Details tells nobody which details."
            ],
            wcagRef: "2.4.2",
            wcagTitle: "Page Titled",
            testYourself: "Turn on VoiceOver, push four screens deep, then swipe back one at a time. Does each screen announce its own name?",
            demo: .none
        )
    ]
}
