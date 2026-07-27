import SwiftUI

/// Topic list for one category — a big illustrated header over a stack of topic
/// cards that stagger in. Each row deep-links to its `TopicDetailView`.
struct CategoryDetailView: View {
    let category: AccessibilityCategory
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var topics: [LearnTopic] { LearnContent.topics(for: category) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                header
                VStack(spacing: Spacing.md) {
                    ForEach(Array(topics.enumerated()), id: \.element) { index, topic in
                        NavigationLink(value: topic) {
                            TopicRow(topic: topic, index: index + 1)
                        }
                        .buttonStyle(.pressableCard)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 22)
                        .animation(
                            reduceMotion ? .easeInOut(duration: 0.2)
                                         : AnimationTokens.spring.delay(Double(index) * 0.06),
                            value: appeared
                        )
                    }
                }
                .padding(.horizontal, Spacing.xl)
            }
            .padding(.top, Spacing.lg)
            .padding(.bottom, 110)
        }
        .background(AllyBackground(accent: category.color))
        .scrollIndicators(.hidden)
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : AnimationTokens.spring) {
                appeared = true
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(category.title.uppercased())
                    .font(Typography.eyebrow)
                    .foregroundStyle(category.inkColor)
                Text(category.tagline)
                    .font(Typography.title1)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(topics.count) topics")
                    .font(Typography.footnote.weight(.semibold))
                    .foregroundStyle(ColorTokens.textSecondary)
            }
            Spacer(minLength: 0)
            CategoryIllustration(category: category, size: 96)
        }
        .padding(.horizontal, Spacing.xl)
    }
}

private struct TopicRow: View {
    let topic: LearnTopic
    let index: Int

    var body: some View {
        HStack(spacing: Spacing.lg) {
            ZStack {
                Circle().fill(topic.category.color.opacity(0.16))
                Text("\(index)")
                    .font(Typography.headline)
                    .foregroundStyle(topic.category.inkColor)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(topic.title)
                    .font(Typography.headline)
                    .foregroundStyle(ColorTokens.textPrimary)
                Text(topic.whatItIs)
                    .font(Typography.subheadline)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(ColorTokens.textTertiary)
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
                .fill(ColorTokens.surfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
                .stroke(ColorTokens.border, lineWidth: 0.5)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(topic.title). \(topic.whatItIs)")
    }
}
