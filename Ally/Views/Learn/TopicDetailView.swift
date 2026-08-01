import SwiftUI

/// A single Learn topic: plain-English framing, the interactive demo (the star),
/// a "test it yourself" nudge, and the WCAG reference kept intentionally small.
struct TopicDetailView: View {
    let topic: LearnTopic

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                titleBlock
                whoCard
                section("Why it matters", topic.whyItMatters)
                demoSection
                testYourselfCard
                wcagFooter
            }
            .padding(Spacing.xl)
            .padding(.bottom, 110)
        }
        .background(AllyBackground(accent: topic.category.color))
        .scrollIndicators(.hidden)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Title

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                Circle().fill(topic.category.color).frame(width: 10, height: 10)
                Text(topic.category.title.uppercased())
                    .font(Typography.eyebrow)
                    .foregroundStyle(topic.category.inkColor)
            }
            Text(topic.title)
                .font(Typography.display)
                .foregroundStyle(ColorTokens.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text(topic.whatItIs)
                .font(Typography.title3)
                .foregroundStyle(ColorTokens.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var whoCard: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(topic.category.inkColor)
                .frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Who this is for")
                    .font(Typography.footnote.weight(.bold))
                    .foregroundStyle(topic.category.inkColor)
                Text(topic.whoItHurts)
                    .font(Typography.body)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
                .fill(topic.category.color.opacity(0.12))
        )
        .accessibilityElement(children: .combine)
    }

    private func section(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(Typography.headline)
                .foregroundStyle(ColorTokens.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text(body)
                .font(Typography.body)
                .foregroundStyle(ColorTokens.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Demo

    @ViewBuilder private var demoSection: some View {
        if case .none = topic.demo {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("See the difference")
                    .font(Typography.headline)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                TopicDemoView(demo: topic.demo)
                Text("Drag the handle to reveal the accessible version.")
                    .font(Typography.caption)
                    .foregroundStyle(ColorTokens.textTertiary)
            }
        }
    }

    private var testYourselfCard: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(ColorTokens.brandSupportInk)
                .frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Test it yourself")
                    .font(Typography.footnote.weight(.bold))
                    .foregroundStyle(ColorTokens.brandSupportInk)
                Text(topic.testYourself)
                    .font(Typography.body)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
                .fill(ColorTokens.brandSupport.opacity(0.14))
        )
        .accessibilityElement(children: .combine)
    }

    private var wcagFooter: some View {
        HStack(spacing: Spacing.sm) {
            Text(topic.wcagRef)
                .font(Typography.mono)
                .foregroundStyle(ColorTokens.onFill(ColorTokens.textSecondary))
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xxs)
                .background(Capsule().fill(ColorTokens.textSecondary))
            Text("WCAG · \(topic.wcagTitle)")
                .font(Typography.footnote)
                .foregroundStyle(ColorTokens.textTertiary)
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Maps to WCAG criterion \(topic.wcagRef), \(topic.wcagTitle)")
    }
}

// MARK: - Demo renderer

private struct TopicDemoView: View {
    let demo: LearnDemo

    var body: some View {
        switch demo {
        case let .contrast(goodFG, goodBG, badFG, badBG):
            BeforeAfterSlider(height: 150) {
                sampleText(fg: badFG, bg: badBG)
            } after: {
                sampleText(fg: goodFG, bg: goodBG)
            }
        case let .textReveal(before, after, caption):
            VStack(alignment: .leading, spacing: Spacing.sm) {
                BeforeAfterSlider(height: 150) {
                    textCard(before, muted: true)
                } after: {
                    textCard(after, muted: false)
                }
                Text(caption)
                    .font(Typography.caption)
                    .foregroundStyle(ColorTokens.textTertiary)
            }
        case .colorOnly:
            BeforeAfterSlider(height: 150) {
                statusCard(showLabels: false)
            } after: {
                statusCard(showLabels: true)
            }
        case .touchTarget:
            TouchTargetDemo()
        case .none:
            EmptyView()
        }
    }

    private func sampleText(fg: UInt32, bg: UInt32) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Save 20% today")
                .font(Typography.title3)
            Text("Tap to redeem your member discount before it expires tonight.")
                .font(Typography.subheadline)
        }
        .foregroundStyle(Color(hex: fg))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .background(Color(hex: bg))
    }

    private func textCard(_ text: String, muted: Bool) -> some View {
        Text(text)
            .font(muted ? Typography.subheadline : Typography.bodyEmph)
            .foregroundStyle(muted ? ColorTokens.textTertiary : ColorTokens.textPrimary)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(Spacing.lg)
            .background(ColorTokens.surfaceElevated)
    }

    private func statusCard(showLabels: Bool) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            row(color: ColorTokens.success, icon: "checkmark.circle.fill", label: "Paid", show: showLabels)
            row(color: ColorTokens.error, icon: "exclamationmark.triangle.fill", label: "Failed", show: showLabels)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .background(ColorTokens.surfaceElevated)
    }

    private func row(color: Color, icon: String, label: String, show: Bool) -> some View {
        HStack(spacing: Spacing.sm) {
            if show {
                Image(systemName: icon).foregroundStyle(color)
            }
            Circle().fill(color).frame(width: 16, height: 16)
            if show {
                Text(label).font(Typography.body).foregroundStyle(ColorTokens.textPrimary)
            }
        }
    }
}

/// Interactive touch-target demo: a 24pt vs 44pt target the user can actually
/// try to tap; the hit ring flashes on success.
private struct TouchTargetDemo: View {
    @State private var lastHit: String?

    var body: some View {
        HStack(spacing: Spacing.xl) {
            target(size: 24, label: "24pt", tag: "Too small")
            target(size: 44, label: "44pt", tag: "Just right")
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                .fill(ColorTokens.surfaceElevated)
        )
    }

    private func target(size: CGFloat, label: String, tag: String) -> some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                Circle().stroke(ColorTokens.motor.opacity(0.35),
                                style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                    .frame(width: 44, height: 44)
                Button {
                    lastHit = label
                    Haptics.light()
                } label: {
                    Circle().fill(ColorTokens.motor)
                        .frame(width: size, height: size)
                        .scaleEffect(lastHit == label ? 1.25 : 1)
                        .allyAnimation(AnimationTokens.bouncy, value: lastHit)
                }
                .buttonStyle(.plain)
                .frame(width: 44, height: 44) // keep a fair 44pt hit area for the demo
            }
            Text(label).font(Typography.mono).foregroundStyle(ColorTokens.textPrimary)
            Text(tag).font(Typography.caption2).foregroundStyle(ColorTokens.textTertiary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) target, \(tag)")
    }
}
