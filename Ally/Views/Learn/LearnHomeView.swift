import SwiftUI

/// Hero tab — the accessibility encyclopedia as a *dictionary / cheat sheet*, not
/// a course. Search-first, with category filter chips over a magazine grid of
/// topic cards. No progress tracking: you browse and reference, you don't
/// "complete" it.
struct LearnHomeView: View {
    @State private var searchText = ""
    @State private var selectedCategory: AccessibilityCategory?
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let columns = [GridItem(.adaptive(minimum: 160), spacing: Spacing.md)]

    /// Topics after applying the active category chip and search text.
    private var filtered: [LearnTopic] {
        let base = selectedCategory.map { LearnContent.topics(for: $0) } ?? LearnContent.all
        let q = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return base }
        return base.filter {
            $0.title.lowercased().contains(q) || $0.whatItIs.lowercased().contains(q)
        }
    }

    /// Browse mode (grouped by category) only when nothing is being filtered.
    private var isBrowsing: Bool {
        selectedCategory == nil && searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    hero
                    searchField
                    categoryChips
                    if isBrowsing {
                        groupedSections
                    } else {
                        filteredGrid
                    }
                }
                .padding(.top, Spacing.xxl)
                .padding(.bottom, 110) // clear the floating tab bar
            }
            .background(AllyBackground())
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.immediately)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: AccessibilityCategory.self) { CategoryDetailView(category: $0) }
            .navigationDestination(for: LearnTopic.self) { TopicDetailView(topic: $0) }
            .onAppear {
                withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : AnimationTokens.spring) {
                    appeared = true
                }
            }
        }
    }

    // MARK: Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("ACCESSIBILITY, MADE TACTILE")
                .font(Typography.eyebrow)
                .foregroundStyle(ColorTokens.brandPrimaryInk)
            Text("Learn")
                .font(Typography.display)
                .foregroundStyle(ColorTokens.textPrimary)
            Text("Your plain-English cheat sheet for accessibility. Search a term or browse by lens — \(LearnContent.all.count) topics, zero jargon.")
                .font(Typography.callout)
                .foregroundStyle(ColorTokens.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.xl)
    }

    // MARK: Search

    private var searchField: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(ColorTokens.textTertiary)
                .accessibilityHidden(true)
            TextField("Search topics", text: $searchText)
                .font(Typography.body)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
            if !searchText.isEmpty {
                Button {
                    withAnimation(AnimationTokens.snappy) { searchText = "" }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(ColorTokens.textTertiary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, Spacing.md)
        .frame(minHeight: 50)
        .background(RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
            .fill(ColorTokens.surfaceElevated))
        .overlay(RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
            .stroke(ColorTokens.border, lineWidth: 0.5))
        .padding(.horizontal, Spacing.xl)
    }

    // MARK: Category chips

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                chip(title: "All", color: ColorTokens.brandPrimary, selected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(AccessibilityCategory.allCases) { cat in
                    chip(title: cat.title, color: cat.color, selected: selectedCategory == cat) {
                        selectedCategory = cat
                    }
                }
            }
            .padding(.horizontal, Spacing.xl)
        }
    }

    private func chip(title: String, color: Color, selected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.selection()
            withAnimation(AnimationTokens.snappy) { action() }
        } label: {
            Text(title)
                .font(Typography.subheadline.weight(.semibold))
                .foregroundStyle(selected ? ColorTokens.onBrand : ColorTokens.textSecondary)
                .padding(.horizontal, Spacing.md)
                .frame(minHeight: 44)
                .background(Capsule().fill(selected ? color : ColorTokens.surfaceElevated))
                .overlay(Capsule().stroke(selected ? Color.clear : ColorTokens.border, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) topics")
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: Content — filtered grid

    @ViewBuilder private var filteredGrid: some View {
        if filtered.isEmpty {
            emptyResults
        } else {
            LazyVGrid(columns: columns, spacing: Spacing.md) {
                ForEach(Array(filtered.enumerated()), id: \.element.id) { index, topic in
                    card(topic, index: index)
                }
            }
            .padding(.horizontal, Spacing.xl)
        }
    }

    private var emptyResults: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(ColorTokens.textTertiary)
            Text("No topics match “\(searchText)”")
                .font(Typography.headline)
                .foregroundStyle(ColorTokens.textPrimary)
                .multilineTextAlignment(.center)
            Text("Try a different word, or clear the search to browse everything.")
                .font(Typography.subheadline)
                .foregroundStyle(ColorTokens.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
        .padding(.horizontal, Spacing.xl)
    }

    // MARK: Content — grouped browse

    private var groupedSections: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            ForEach(AccessibilityCategory.allCases) { category in
                let topics = LearnContent.topics(for: category)
                VStack(alignment: .leading, spacing: Spacing.md) {
                    sectionHeader(category, count: topics.count)
                    LazyVGrid(columns: columns, spacing: Spacing.md) {
                        ForEach(Array(topics.enumerated()), id: \.element.id) { index, topic in
                            card(topic, index: index)
                        }
                    }
                }
                .padding(.horizontal, Spacing.xl)
            }
        }
    }

    private func sectionHeader(_ category: AccessibilityCategory, count: Int) -> some View {
        HStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                CategoryIllustration(category: category, size: 34)
                Text(category.title)
                    .font(Typography.title3)
                    .foregroundStyle(ColorTokens.textPrimary)
                Text("\(count)")
                    .font(Typography.caption.weight(.bold))
                    .foregroundStyle(category.inkColor)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(category.color.opacity(0.16)))
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(category.title), \(count) topics")
            .accessibilityAddTraits(.isHeader)

            Spacer(minLength: 0)

            NavigationLink(value: category) {
                Text("See all")
                    .font(Typography.footnote.weight(.semibold))
                    .foregroundStyle(category.inkColor)
                    .padding(.horizontal, Spacing.sm)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("See all \(category.title) topics")
        }
    }

    // MARK: Shared card builder (staggered entrance)

    private func card(_ topic: LearnTopic, index: Int) -> some View {
        NavigationLink(value: topic) {
            TopicCard(topic: topic)
        }
        .buttonStyle(.pressableCard)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(
            reduceMotion ? .easeInOut(duration: 0.2)
                         : AnimationTokens.spring.delay(Double(min(index, 8)) * 0.05),
            value: appeared
        )
    }
}

// MARK: - Magazine topic card

private struct TopicCard: View {
    let topic: LearnTopic

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Category color accent strip.
            Rectangle()
                .fill(topic.category.color)
                .frame(height: 6)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(topic.category.title.uppercased())
                    .font(Typography.caption2.weight(.bold))
                    .foregroundStyle(topic.category.inkColor)
                Text(topic.title)
                    .font(Typography.headline)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(topic.whatItIs)
                    .font(Typography.subheadline)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: Spacing.sm)
                Text("WCAG \(topic.wcagRef)")
                    .font(Typography.caption2.weight(.semibold))
                    .foregroundStyle(topic.category.inkColor)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(topic.category.color.opacity(0.14)))
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, minHeight: 184, alignment: .topLeading)
        .background(ColorTokens.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
            .stroke(ColorTokens.border, lineWidth: 0.5))
        .shadow(color: topic.category.color.opacity(0.12), radius: 10, y: 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(topic.title). \(topic.category.title). \(topic.whatItIs)")
        .accessibilityHint("Opens the topic")
    }
}

#Preview { LearnHomeView() }
