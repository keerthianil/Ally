# Ally

**Accessibility, made tactile.** A bold, playful iOS app that teaches accessibility, scores your project against it, and hands you the tools to fix it — the a11y reference that doesn't read like the spec.

The name comes from **a11y** ("ally"). Think Duolingo meets Apple's Human Interface Guidelines, for accessibility.

<!-- ![App Screenshot](Screenshots/hero.png) -->

## The Problem

94.8% of the top million home pages have detectable WCAG failures. Everyone says they should care about accessibility; almost nobody knows where to start. The existing tools split into design-phase plugins (Stark) and expensive dev-phase scanners (axe DevTools at $15K+/yr) — with an empty, affordable middle, essentially no iOS-native *learning* tool, and almost nothing for **cognitive** accessibility, the most underserved area of all. People don't fail at accessibility because they don't care; they fail because WCAG is written for auditors, not for the person shipping the screen.

Ally is **Duolingo meets Apple's HIG, for accessibility.**

## The Three Tabs

| Tab | What it does |
|-----|--------------|
| **Learn** | A plain-English **dictionary / cheat sheet** — 27 topics across Vision, Motor, Cognitive, and Navigation. Search-first, filterable by lens, with a magazine card grid. Each topic: what it is, who it's for, why it matters, an **interactive before/after demo**, and the WCAG reference kept small. No progress bars — you reference it, you don't "finish" it. |
| **Check** | A plain-English **self-assessment**. Create a project → answer 20 guided checkpoints → get a 0–100 accessibility score on a custom animated ring, a per-category breakdown, a trend chart, and a prioritized fix-list that deep-links back into Learn. Completing a check opens a **celebration screen** before the report; export a PDF when you're done. |
| **Toolkit** | Five practical tools: a **Contrast Checker** (live ratio + plain-English verdict + auto-fix), a **Color-Blindness Simulator** (8 CVD types via Core Image), a **Text Readability** checker (Flesch-Kincaid + jargon flags), a **Touch-Target Calculator** (44 / 48 / 24 minimums, to-scale), and a searchable **WCAG Quick Reference** that deep-links into Learn. |

## Ally passes its own Check

An accessibility tool that fails its own standards has no credibility, so Ally is built to clear everything it teaches:

- **VoiceOver** — every control labeled with intent; the score ring announces its score and per-category values; the before/after demo is exposed as an adjustable slider; swipe-to-delete also offers a VoiceOver custom action; decorative art is hidden from the tree.
- **Automated audit** — a UI-test target runs Apple's `performAccessibilityAudit` across all three tabs and the deeper screens on every test pass (element detection, ≥44 pt hit regions, descriptions, traits). It caught a real bug where the custom tab bar's icons reported a ~20 pt hit area.
- **Dynamic Type** — everything scales to the largest accessibility sizes; no fixed-height text.
- **Reduce Motion** — springs become crossfades, confetti becomes a static sparkle, the animated illustrations settle to a still frame.
- **Color** — `ColorTokenContrastTests` recomputes every token pair from the shipping values, in **both** appearances, and fails the build on a regression. Pass/fail is never color-only.

## Design — "Grape Fizz"

A deliberately un-corporate palette: berry-magenta hero, tangerine support, golden celebration, and a citrus category quartet (cyan / tangerine / violet / emerald). SF Pro Rounded for display type, a signature animated backdrop (concentric arcs + spiral + blooms), custom `Canvas`-drawn category illustrations, and a hand-rolled spring-animated tab bar. Dark mode is a first-class citizen.

## Tech

- SwiftUI + SwiftData (iOS 17+), no ViewModels — state via `@State` / `@Query`
- Core Image (`CIColorMatrix`) for the 8-type CVD simulation
- `Canvas` for the multi-segment score ring, confetti, and category art
- Swift Charts for the score trend
- `UIGraphicsPDFRenderer` for the exportable report
- Centralized design tokens (color / type / spacing / corner radius / animation / haptics)
- No backend — everything stays on device

## Architecture

```
Ally/
├── Utilities/     Design tokens: ColorTokens, Typography, Spacing,
│                  CornerRadius, AnimationTokens, Haptics, ContrastMath
├── Models/        Project, Checkpoint, CheckpointHistory (SwiftData)
├── Data/          LearnContent (27 topics), CheckpointBank, WCAGCriteria,
│                  ScoreEngine, DemoSeed
├── Components/    ScoreRing, ConfettiView, BeforeAfterSlider,
│                  CategoryIllustration, AllyBackground, PressableCardStyle
├── Views/
│   ├── Learn/     Home (search + magazine grid), CategoryDetail, TopicDetail
│   ├── Check/     Home, NewProject, CheckpointFlow, Celebration, ScoreResult
│   └── Toolkit/   Contrast, CVDSimulator, Readability, TouchTarget, WCAGReference
└── Resources/     Assets.xcassets
AllyUITests/       Automated accessibility audit
```

## Running It

This project is generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen); `Ally.xcodeproj` is committed so it opens directly.

1. Clone this repo
2. Open `Ally.xcodeproj` in Xcode 15+
3. Select an iPhone (simulator or device) and build (⌘R)

If you change files or `project.yml`, run `xcodegen generate` to regenerate the project.

## Design Decisions

**Learn is a dictionary, not a course.** Accessibility is a reference you return to, not a level you complete — so there's no progress tracking or completion pressure anywhere in the Learn tab.

**Celebrate before you analyze.** Finishing a check lands on an encouraging, band-specific celebration screen first; the dense report is one tap away. Low scores get warm, non-punishing copy — accessibility guilt is the feeling Ally is trying to remove.

**"Not sure" doesn't hurt your score.** In the Check flow, "Not sure" is excluded from the denominator so honesty isn't punished — it's tracked separately as items to revisit.

**Math is automated; judgment stays human.** Contrast and color-distinguishability are math, so the Toolkit computes them exactly. Everything that needs semantic context (labels, focus order) is taught, not faked.

**An ink needs an appearance.** Every saturated fill ships an `…Ink` variant for text — but a fixed ink can only ever be right in one mode. A magenta dark enough to read on `#FDF4FA` drops to 2.95:1 on the dark surface; a cyan bright enough for dark mode reads at 1.97:1 on light. The inks are adaptive, and `onFill(_:)` picks white or aubergine by measuring rather than by assuming. Six pairs were failing before this was measured — including the score-ring arcs, which at 1.75:1 against their own tracks were effectively invisible in light mode.
