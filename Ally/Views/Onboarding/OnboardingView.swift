import SwiftUI

/// Shown once, on first launch.
///
/// Four cards, skippable from the first one. It exists for two reasons that
/// justify the interruption, and deliberately does nothing else:
///
/// 1. **Ask Ally is invisible.** It is a sparkle button next to a search field.
///    Nobody discovers "this answers accessibility questions from a fixed corpus,
///    on device, and refuses anything outside it" by tapping a sparkle.
/// 2. **The framing is the product.** Learn is a dictionary, not a course, and
///    Check is a self-assessment, not an audit. Users arrive expecting a scanner
///    that grades them. Saying so up front costs one screen and prevents the
///    entire wrong mental model.
///
/// It does not ask for permissions, an account, or a name. There is nothing to
/// set up, so there is nothing to configure.
struct OnboardingView: View {
    var onFinish: () -> Void

    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var pages: [Page] { Page.all }

    var body: some View {
        ZStack {
            AllyBackground(accent: pages[page].accent)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { i, p in
                        PageBody(page: p).tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                footer
            }
        }
        // VoiceOver reads a paged TabView as one element unless each page is its
        // own container, and it will not announce the change of page by itself.
        .onChange(of: page) { _, new in
            AccessibilityNotification.Announcement(
                "\(pages[new].title). Step \(new + 1) of \(pages.count)."
            ).post()
        }
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Text("ALLY")
                .font(Typography.eyebrow)
                .foregroundStyle(ColorTokens.brandPrimaryInk)
            Spacer()
            Button("Skip") { finish() }
                .font(Typography.subheadline.weight(.semibold))
                .foregroundStyle(ColorTokens.textSecondary)
                .frame(minWidth: 60, minHeight: 44)
                .contentShape(Rectangle())
                .accessibilityHint("Goes straight to the app")
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.top, Spacing.md)
    }

    // MARK: Footer

    private var footer: some View {
        VStack(spacing: Spacing.lg) {
            // Progress as dots, plus a spoken position, so the count is never
            // colour-only or shape-only.
            HStack(spacing: Spacing.sm) {
                ForEach(0..<pages.count, id: \.self) { i in
                    Capsule()
                        .fill(i == page ? ColorTokens.brandPrimary : ColorTokens.border)
                        .frame(width: i == page ? 26 : 8, height: 8)
                        .allyAnimation(AnimationTokens.snappy, value: page)
                }
            }
            // The dots are 8pt tall. As an accessibility element that fails the
            // 44pt minimum, and the audit measures the element rather than any
            // tap handler. A frame alone does not fix it, because with no
            // background the element's rect still collapses to its content, so
            // `contentShape` is what actually widens it.
            .frame(minWidth: 88, minHeight: 44)
            .contentShape(Rectangle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Step \(page + 1) of \(pages.count)")

            Button {
                Haptics.light()
                if page < pages.count - 1 {
                    withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : AnimationTokens.spring) {
                        page += 1
                    }
                } else {
                    finish()
                }
            } label: {
                Text(page < pages.count - 1 ? "Next" : "Start using Ally")
                    .font(Typography.headline)
                    .foregroundStyle(ColorTokens.onFill(ColorTokens.brandPrimary))
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background(Capsule().fill(ColorTokens.brandPrimary))
                    .contentTransition(.identity)
            }
            .buttonStyle(.pressableCard)
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.bottom, Spacing.xl)
    }

    private func finish() {
        Haptics.success()
        onFinish()
    }
}

// MARK: - Page model

extension OnboardingView {
    struct Page {
        let eyebrow: String
        let title: String
        let body: String
        /// The one thing this page wants you to remember, stated as a claim.
        let pin: String
        let accent: Color
        let art: Art

        enum Art { case lenses, check, toolkit, assistant }

        static var all: [Page] {
            [
                Page(eyebrow: "WHAT THIS IS",
                     title: "A dictionary, not a course",
                     body: "\(LearnContent.all.count) accessibility topics in plain English, grouped by who they affect rather than by spec section. Look something up, close the app, come back next week.",
                     pin: "No streaks. No progress bar. Nothing to finish.",
                     accent: ColorTokens.vision,
                     art: .lenses),
                Page(eyebrow: "CHECKING YOUR WORK",
                     title: "A self-assessment, not an audit",
                     body: "Answer 20 plain questions about a project and get a score you can act on. Every low answer links straight to the topic that explains it.",
                     pin: "\"Not sure\" does not count against you. Honesty is more useful than a guess.",
                     accent: ColorTokens.navigation,
                     art: .check),
                Page(eyebrow: "WHILE YOU WORK",
                     title: "Five tools for the actual job",
                     body: "Contrast ratios, a colour-blindness simulator across eight types, reading level, touch-target sizes, and the spec in plain words.",
                     pin: "The maths is exact. The judgement stays yours.",
                     accent: ColorTokens.motor,
                     art: .toolkit),
                Page(eyebrow: "ASK ALLY",
                     title: "Answers from these topics only",
                     body: "Tap the sparkle next to search and ask in your own words, typos and shorthand included. Answers are generated on your iPhone and always name the topic they came from.",
                     pin: assistantPin,
                     accent: ColorTokens.cognitive,
                     art: .assistant)
            ]
        }

        /// Told the truth up front rather than discovered as a dead end. On most
        /// devices this feature does not exist, and the app is complete without it.
        private static var assistantPin: String {
            AllyIntelligence.status.isReady
            ? "If it does not cover something, it says so instead of guessing."
            : "Needs iOS 26 and Apple Intelligence, which this iPhone does not have. Everything else works exactly the same."
        }
    }
}

// MARK: - Page body

private struct PageBody: View {
    let page: OnboardingView.Page

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Spacer(minLength: 0)

            OnboardingArt(kind: page.art, accent: page.accent)
                .frame(height: 200)
                .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(page.eyebrow)
                    .font(Typography.eyebrow)
                    .foregroundStyle(ColorTokens.brandPrimaryInk)
                Text(page.title)
                    .font(Typography.title1)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(page.body)
                    .font(Typography.callout)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(alignment: .top, spacing: Spacing.sm) {
                Image(systemName: "pin.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(page.accent.opacity(0.9))
                    .accessibilityHidden(true)
                Text(page.pin)
                    .font(Typography.footnote.weight(.semibold))
                    .foregroundStyle(ColorTokens.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                .fill(ColorTokens.surfaceElevated))
            .overlay(RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                .stroke(ColorTokens.border, lineWidth: 1))

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.xl)
        // One page, one VoiceOver container, read top to bottom.
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Art

/// Purpose-built art per page, reusing the living category and tool marks so
/// onboarding looks like the app rather than like a separate marketing asset.
private struct OnboardingArt: View {
    let kind: OnboardingView.Page.Art
    let accent: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            switch kind {
            case .lenses:
                // The four lenses fanned out, which is literally the Learn tab.
                HStack(spacing: -Spacing.md) {
                    ForEach(Array(AccessibilityCategory.allCases.enumerated()), id: \.element) { i, cat in
                        ZStack {
                            NotchedCard(notch: 28)
                                .fill(cat.color)
                                .frame(width: 76, height: 108)
                            LivingCategoryArt(category: cat, size: 40, onCategoryFill: true)
                                .offset(y: -8)
                        }
                        .rotationEffect(.degrees(Double(i) * 7 - 10))
                        .floating(i, amplitude: 4)
                    }
                }
            case .check:
                CheckPreviewArt()
            case .toolkit:
                HStack(spacing: Spacing.md) {
                    ForEach(Array([LivingToolArt.Kind.contrast, .cvd, .readability, .touchTarget].enumerated()), id: \.offset) { i, k in
                        LivingToolArt(kind: k, tint: ColorTokens.motor, ink: ColorTokens.motorInk, size: 56)
                            .padding(Spacing.md)
                            .background(RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                                .fill(ColorTokens.surfaceElevated))
                            .floating(i, amplitude: 4)
                    }
                }
            case .assistant:
                AssistantPreviewArt()
            }
        }
        .accessibilityHidden(true)
    }
}

/// A score ring filling and settling, so the Check page shows the payoff rather
/// than describing it.
private struct CheckPreviewArt: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if reduceMotion {
                ring(progress: 0.82, score: 82)
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                    let p = Living.pulse(Living.phase(timeline.date), period: 4.4)
                    ring(progress: 0.34 + 0.48 * p, score: Int(34 + 48 * p))
                }
            }
        }
    }

    private func ring(progress: Double, score: Int) -> some View {
        ZStack {
            Circle()
                .stroke(ColorTokens.navigation.opacity(0.28), lineWidth: 16)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(ColorTokens.navigationInk, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(score)")
                .font(Typography.title1)
                .foregroundStyle(ColorTokens.textPrimary)
                .monospacedDigit()
        }
        .frame(width: 148, height: 148)
    }
}

/// A question and a cited answer, typing itself out. The citation is the point
/// of the feature, so it is the thing the art ends on.
private struct AssistantPreviewArt: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let answer = "Body text needs 4.5 to 1."

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("how much contarst do i need")
                .font(Typography.footnote)
                .foregroundStyle(ColorTokens.onFill(ColorTokens.brandPrimaryInk))
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(Capsule().fill(ColorTokens.brandPrimaryInk))
                .frame(maxWidth: .infinity, alignment: .trailing)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                if reduceMotion {
                    Text(answer).font(Typography.subheadline)
                } else {
                    TimelineView(.animation(minimumInterval: 1.0 / 12.0)) { timeline in
                        let p = Living.sweep(Living.phase(timeline.date), period: 5.0)
                        let shown = min(answer.count, Int(Double(answer.count) * min(1, p * 1.8)))
                        Text(String(answer.prefix(shown)) + " ")
                            .font(Typography.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "book.closed.fill").font(.system(size: 10, weight: .bold))
                    Text("Color Contrast").font(Typography.caption2.weight(.semibold))
                }
                .foregroundStyle(ColorTokens.cognitiveInk)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, 4)
                .background(Capsule().fill(ColorTokens.cognitive.opacity(0.30)))
            }
            .foregroundStyle(ColorTokens.textPrimary)
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                .fill(ColorTokens.surfaceElevated))
        }
        .padding(.horizontal, Spacing.lg)
    }
}

#Preview { OnboardingView {} }
