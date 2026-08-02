# Ally

**Accessibility, made tactile.** A bold, playful iOS app that teaches accessibility, scores your project against it, and hands you the tools to fix it — the a11y reference that doesn't read like the spec.

The name comes from **a11y** ("ally"). Think Duolingo meets Apple's Human Interface Guidelines, for accessibility.

<!-- ![App Screenshot](Screenshots/hero.png) -->

## The Problem

95.9% of the top million home pages have detectable WCAG failures, at an average of 56 errors per page — and that figure went *up* in 2026, reversing six years of small gains ([WebAIM Million, 2026](https://webaim.org/projects/million/)). Everyone says they should care about accessibility; almost nobody knows where to start. The existing tools split into design-phase plugins (Stark) and expensive dev-phase scanners (axe DevTools at $15K+/yr) — with an empty, affordable middle, essentially no iOS-native *learning* tool, and almost nothing for **cognitive** accessibility, the most underserved area of all. People don't fail at accessibility because they don't care; they fail because WCAG is written for auditors, not for the person shipping the screen.

Ally is **Duolingo meets Apple's HIG, for accessibility.**

## The Three Tabs

| Tab | What it does |
|-----|--------------|
| **Learn** | A plain-English **dictionary**, not a course — **55 topics** across Vision, Motor, Cognitive, and Navigation. Browse opens on four lens cards; searching switches to a two-column masonry. Each topic covers what it is, who it's for, why it matters, **what it looks like when it's wrong**, two to four concrete iOS fixes, an interactive before/after demo, and a way to test it yourself. No progress bars — you reference it, you don't "finish" it. |
| **Check** | A plain-English **self-assessment**. Create a project → answer 20 guided checkpoints → get a 0–100 score on a custom animated ring, a per-category breakdown, a trend chart, and a prioritized fix-list that deep-links back into Learn. Finishing lands on a **celebration screen** whose reaction matches your band before the dense report. Export a PDF when you're done. |
| **Toolkit** | Five practical tools: a **Contrast Checker** (live ratio + plain-English verdict + auto-fix), a **Color-Blindness Simulator** (8 CVD types via Core Image), a **Text Readability** checker (Flesch-Kincaid + jargon flags, with an optional on-device rewrite), a **Touch-Target Calculator** (44 / 48 / 24 minimums, to-scale), and a **WCAG Quick Reference** built as a deck of **50 flash cards**. |

### The quick reference is a deck, not a list

A reference you have to *read* isn't quick. So the WCAG tool shows one criterion at a time on a card you turn over:

- **Front** — the number, the conformance level, the name, and the rule in one sentence.
- **Back** — what to actually do, and the classic failure so you can recognise it on sight.

Anything longer lives one tap away in Learn, and `WCAGCriterion` structurally cannot hold more than those three short strings — a test fails the build if any of them exceeds 110 characters. Narrow the deck by POUR principle or conformance level, jump straight to a number from the index, or search. Previous, Flip, and Next are all real buttons; the swipe is only a shortcut, because a gesture-only deck would fail WCAG 2.5.1 in an app about WCAG 2.5.1.

### Ask Ally — on-device, or not at all

On iOS 26 with Apple Intelligence, Learn has a **retrieve-then-generate** assistant built on Foundation Models. Retrieval runs *before* any model call and is the refusal mechanism: the model only ever sees passages drawn from Ally's own 55 topics and 50 criteria, so it can't invent a contrast ratio or a target size. Off-topic questions never reach it. It understands how practitioners actually type — abbreviations (`vo`, `a11y`, `aa`, `coga`), ~180 synonyms (nobody asks about "Use of Color"; they ask whether red and green is enough), and typos, via a length-scaled Damerau-Levenshtein correction that can only ever snap a word *towards* something Ally covers.

Every availability state — old OS, unsupported device, Apple Intelligence off, model still downloading — is a real designed screen, not a silent failure, and `-forceAIStatus` lets any of them be tested on any device.

## Ally passes its own Check

An accessibility tool that fails its own standards has no credibility, so this is enforced rather than asserted — **98 tests**, 80 unit and 18 UI:

- **Automated audit** — `AllyAccessibilityAuditTests` runs Apple's `performAccessibilityAudit` across all three tabs, onboarding, the report, the flash-card deck, and both AI surfaces. It caught a real bug where the custom tab bar's icons reported a ~20 pt hit area.
- **What VoiceOver actually says** — an audit checks that elements *have* labels, not that the labels are any good. `VoiceOverContractTests` walks the real tree and fails on labels that are SF Symbol names or identifiers, and on labels repeated so often that Voice Control can't disambiguate them. It found every text input in the app relying on its placeholder as its label — the exact thing Learn has a topic telling you not to do.
- **Color** — `ColorTokenContrastTests` recomputes every token pair from the shipping values, in **both** appearances, and fails the build on a regression. It also measures that the three score bands are far enough apart to be told apart at a glance. Pass/fail is never color-only.
- **Content integrity** — the Learn topics and the WCAG table point at each other by loose string id, which nothing in the compiler checks. `ContentIntegrityTests` verifies every link resolves in both directions, and that every topic is retrievable by the assistant using its own title.
- **Dynamic Type** — everything scales to the largest accessibility sizes; no fixed-height text.
- **Reduce Motion** — springs become crossfades, and every ambient animation resolves to a composed *still frame*, never frame zero.

## Motion, and where it stops

`LivingArt.swift` is the whole motion vocabulary: one shared clock, one drift modifier, and a living mark per lens and per tool. The rule throughout is that **motion carries personality, never information** — switching all of it off costs you nothing.

The floating tab bar **minimises on scroll and never hides** at a tab root: a control that vanishes mid-reach is a motor failure, one that's off screen can't be reached by Switch Control or named by Voice Control, and the bar is the "you are here" indicator as much as it is navigation. It's forced fully expanded whenever an assistive technology is running. On a *pushed* screen it goes away entirely — that's the opposite rule for a good reason, and it's what UIKit has done on push since 2008.

## Design — "Grape Fizz", muted

A deliberately un-corporate palette, desaturated in 2026: a blush-cream base, one saturated berry hero, and a pastel category quartet (dusty teal / apricot / periwinkle / sage). Pastels carry the warm aubergine ink at 7.4:1 to 8.6:1, so the system got quieter and simpler at the same time. Every fill ships an adaptive `…Ink` variant, and text on a fill goes through `onFill(_:)`, which measures contrast per-appearance rather than assuming white.

The one place that breaks the palette on purpose is the **score**. Three bands — green at 80+, orange at 50–79, red below 50 — saturated enough to read as a traffic light in sunlight and in peripheral vision. Each band gets its own celebration effect, built on a different motion grammar so they can never be confused: a radial burst, a vertical ember rise, and a slow horizontal sunrise. They vary in *energy*, not in approval; the band's name always ships alongside the colour.

SF Pro Rounded for display type, a signature animated backdrop (concentric arcs + spiral + blooms), custom `Canvas`-drawn art throughout, and a hand-rolled spring-animated tab bar. Dark mode is a first-class citizen.

## Tech

- SwiftUI + SwiftData (iOS 17+), no ViewModels — state via `@State` / `@Query`
- Foundation Models for the on-device assistant and rewriter (iOS 26+, gracefully absent below)
- Core Image (`CIColorMatrix`) for the 8-type CVD simulation
- `Canvas` for the score ring, the celebration effects, and every piece of living art
- Swift Charts for the score trend
- `UIGraphicsPDFRenderer` for the exportable report
- Centralized design tokens (color / type / spacing / corner radius / animation / haptics)
- No backend, no network — everything stays on device

## Architecture

```
Ally/
├── Utilities/     Design tokens: ColorTokens, Typography, Spacing,
│                  CornerRadius, AnimationTokens, Haptics, ContrastMath
├── Models/        Project, Checkpoint, CheckpointHistory (SwiftData)
├── Data/          LearnContent (55 topics), WCAGCriteria (50 criteria),
│                  CheckpointBank, ScoreEngine, DemoSeed
├── Services/      AllyIntelligence (availability chokepoint), AllyAssistant,
│                  AssistantCorpus (retrieval + refusal), PlainLanguageRewriter,
│                  HouseStyle, PDFReportService
├── Components/    ScoreRing, LivingArt, CelebrationEffect, NotchedCard,
│                  BeforeAfterSlider, AllyBackground, TabBarVisibility
├── Views/
│   ├── Onboarding/ First-run only, four pages
│   ├── Learn/     Home (lenses + search masonry), CategoryDetail, TopicDetail
│   ├── Assistant/ Ask Ally chat sheet
│   ├── Check/     Home, NewProject, CheckpointFlow, Celebration, ScoreResult
│   └── Toolkit/   Contrast, CVDSimulator, Readability, TouchTarget,
│                  WCAGReference (the flash-card deck)
└── Resources/     Assets.xcassets
AllyTests/         80 unit tests
AllyUITests/       Accessibility audit, VoiceOver contract, screenshot capture
```

## Running It

This project is generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen); `Ally.xcodeproj` is committed so it opens directly.

1. Clone this repo
2. Open `Ally.xcodeproj` in Xcode 16+
3. Select an iPhone (simulator or device) and build (⌘R)

If you change files or `project.yml`, run `xcodegen generate` to regenerate the project.

```bash
xcodebuild test -scheme Ally -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Launch arguments for screenshots and for testing states you can't otherwise reach:
`-showOnboarding` / `-skipOnboarding`, `-seedDemo`, `-seedBand <strong|building|starting>`,
`-resetStore`, `-tabCheck` / `-tabToolkit`, `-openResult`, `-openCelebration`,
`-openTool <name>`, `-openAssistant`, `-forceAIStatus <ready|osTooOld|deviceUnsupported|notEnabled|modelNotReady>`.

## Design Decisions

**Learn is a dictionary, not a course.** Accessibility is a reference you return to, not a level you complete — so there's no progress tracking or completion pressure anywhere in the Learn tab.

**A reference and a dictionary are different jobs.** The quick reference used to be a searchable list, which was a fine reference and a poor *quick* one: you had to read every entry to find the one you wanted. Splitting it — three short lines on a flash card, everything deeper in Learn — is why both halves got better.

**Celebrate before you analyze.** Finishing a check lands on a band-specific celebration screen first; the dense report is one tap away. A low score gets warm copy and a quiet effect rather than silence, because silence is a verdict too, and accessibility guilt is the feeling Ally exists to remove.

**"Not sure" doesn't hurt your score.** In the Check flow, "Not sure" is excluded from the denominator so honesty isn't punished — it's tracked separately as items to revisit.

**Math is automated; judgment stays human.** Contrast and color-distinguishability are math, so the Toolkit computes them exactly. Everything that needs semantic context (labels, focus order) is taught, not faked.

**The model never answers from memory.** An accessibility app that hallucinates a WCAG threshold is worse than one with no assistant at all. Retrieval decides what the model may see and whether it's called at all, so the refusal is a property of the system rather than an instruction the model could be talked past.

**An ink needs an appearance.** Every fill ships an `…Ink` variant for text — but a fixed ink can only ever be right in one mode. The inks are adaptive, and `onFill(_:)` picks white or aubergine by measuring rather than by assuming. Eighteen pairs were failing before this was measured — including the score-ring arcs, which at 1.75:1 against their own tracks were effectively invisible in light mode.

## Known Gaps

**The exported PDF has no text layer.** `PDFReportService` rasterizes a SwiftUI view via `ImageRenderer`, so the report is an image and is not screen-reader accessible. It's called out here rather than quietly shipped; a real `PDFKit` text layer is the fix.
