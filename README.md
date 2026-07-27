# Ally

**Accessibility, finally clicks.** A bold, playful iOS app that turns WCAG from an impenetrable spec into something you can *feel* — then lets you score your own product against it.

The name comes from **a11y** ("ally"). Ally is the tool for designers and developers who know they *should* care about accessibility but don't know where to start. Think Duolingo meets Apple's Human Interface Guidelines.

<!-- ![App Screenshot](Screenshots/hero.png) -->

## The Problem

94.8% of home pages have detectable WCAG failures, and accessibility is cheapest to fix in the design phase — yet the tooling splits into two camps: design-phase plugins (Stark) and expensive dev-phase scanners (axe DevTools at $15K+/yr). There's an empty, affordable middle, essentially no iOS-native *learning* tool, and almost nothing for **cognitive** accessibility — the most underserved area of all. Most people don't fail at accessibility because they don't care; they fail because WCAG is written for auditors, not for the person shipping the screen.

## Three Tabs, One Loop: Learn → Check → Improve

| Tab | What it does |
|-----|--------------|
| **Learn** (hero) | A searchable **dictionary / cheat sheet** of 27 topics across four plain-English lenses (Vision, Motor, Cognitive, Navigation). Browse-first — no course, no progress bar. Each topic leads with one jargon-free sentence and a real human, then an **interactive demo** that makes you *feel* the barrier. |
| **Check** | A plain-English self-assessment. 20 guided checkpoints → a **celebration** → a 0–100 accessibility score in a custom animated ring, per-category breakdown, a trend over time, and a prioritized fix-list that deep-links into Learn. Export a PDF. |
| **Toolkit** | Five things you reach for mid-work: contrast checker (with one-tap auto-fix), color-blindness simulator (8 CVD types), text readability, touch-target calculator, and a searchable WCAG reference. |

## Signature interactions (the "wow")

- **Drag-to-reveal Before/After sliders** — gesture-tracked demos for contrast, plain language, and color-only reliance. You wipe between the failing and passing state and feel the difference.
- **Touch-target playground** — live 24pt-vs-44pt targets you actually try to tap.
- **Multi-segment ScoreRing** — a hand-drawn `Canvas` ring, one glowing arc per category, that sweep-fills on appear and counts the score up.
- **Completion celebration** — finishing a check lands on a full-screen, band-specific encouraging moment (score-ring sweep + confetti) *before* the dense report.
- **Custom animated tab bar**, spring card reveals, and `.sensoryFeedback` haptics throughout.

## Honest by design

- **"Not sure" is excluded from the score denominator** — honesty isn't punished; unsure items are tracked separately as things to revisit.
- Ally never claims to be a certified audit. It's a self-assessment aid and a teaching tool — and it says so.
- Every brand fill ships a darkened **"ink" variant** that passes WCAG AA for text/links, because an app that teaches contrast has to pass its own checks.

## Tech

- **SwiftUI + SwiftData** (iOS 17+), no ViewModels — state via `@State` / `@Query` / `@Bindable`.
- **Core Image** (`CIColorMatrix`) for real-time color-blindness simulation across 8 CVD types.
- **Canvas / Path** for the custom multi-segment score ring and the confetti burst.
- **Swift Charts** for the score-over-time trend.
- **`UIGraphicsPDFRenderer`** for the exportable Check report.
- **XcodeGen** — the project is generated from `project.yml` (source of truth), so `.xcodeproj` is git-ignored.
- No backend — everything stays on device.

## Design system — "Grape Fizz"

A deliberately loud, Dribbble-viral palette that stays clear of the colors used by sibling projects. Berry-magenta hero (`#D6249F`) + tangerine support + a citrus category quartet (cyan / tangerine / violet / emerald), SF Pro **Rounded** for display type, an 8pt spacing grid, and centralized animation tokens with a Reduce-Motion fallback for every spring. Tokens mirror the caseless-`enum` namespace pattern shared across the portfolio (`ColorTokens`, `Typography`, `Spacing`, `CornerRadius`, `AnimationTokens`).

## Accessibility (it passes its own Check)

VoiceOver labels, hints, and traits on every interactive element · full Dynamic Type (no fixed text sizes) · Reduce Motion swaps springs for crossfades and drops confetti for a static sparkle · ≥44pt targets · every color pair validated at AA. Gorgeous in both light and dark mode.

## Architecture

```
Ally/
├── AllyApp.swift            SwiftData ModelContainer
├── Utilities/               ColorTokens, Typography, Spacing, CornerRadius,
│                            AnimationTokens, Haptics, ContrastMath
├── Models/                  Project, Checkpoint, CheckpointHistory (SwiftData)
├── Data/                    LearnContent, CheckpointBank, WCAGCriteria,
│                            ScoreEngine, AccessibilityCategory, DemoSeed
├── Components/              ScoreRing, ConfettiView, BeforeAfterSlider,
│                            CategoryIllustration, AllyBackground, …
├── Services/                PDFReportService
└── Views/
    ├── RootTabView          custom animated floating tab bar
    ├── Learn/               LearnHome (search + magazine grid), CategoryDetail,
    │                        TopicDetail + interactive demos
    ├── Check/               CheckHome (swipe-to-delete), NewProject, Checkpoint
    │                        flow, Celebration, ScoreResult
    └── Toolkit/             Contrast, CVD Simulator, Readability, Touch Target,
                             WCAG Reference
```

## Running It

1. Clone this repo
2. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`) and run `xcodegen generate` in `Ally App/`
3. Open `Ally.xcodeproj` in Xcode 15+
4. Select an iPhone simulator or your device and build (Cmd+R)

Launch arguments help with demos and screenshots: `-seedDemo` seeds a sample project, `-tabCheck` / `-tabToolkit` open a tab, and `-openCelebration` / `-openResult` / `-openTool <name>` jump straight to a screen.

## Design Decisions

**Learn is a dictionary, not a course.** Accessibility is something you look up and return to — so there's deliberately no "X of N explored" progress bar or completion pressure. The reward loop lives in the Check tab's celebration, where it belongs.

**Celebrate before you analyze.** Completing a check shows an encouraging, band-specific celebration first, *then* the numbers-heavy report — so the moment reads as a reward, not a verdict. Even the lowest score band gets warm, "great start" copy.

**Cognitive accessibility gets equal billing.** It's a full category of Learn topics and Check checkpoints, not an afterthought — because it's the gap almost every other tool ignores.
