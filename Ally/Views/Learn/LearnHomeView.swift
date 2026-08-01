import SwiftUI

/// Hero tab. The accessibility encyclopedia as a dictionary, not a course.
///
/// Two different layouts on purpose, because browsing and looking something up
/// are different jobs:
///
/// - **Browsing** shows the four lenses as four cards, and nothing else. You do
///   not know what you are looking for yet, so the only decision on screen is
///   which kind of person you are designing for. Tapping opens that lens.
/// - **Searching** switches to a vertical masonry column pair. You
///   have a target, so the layout stops being scenic and starts being a list
///   you can scan. Varied heights keep it from reading as a spreadsheet.
///
/// No progress tracking anywhere: you reference this, you don't finish it.
struct LearnHomeView: View {
    @State private var searchText = ""
    @State private var appeared = false
    @State private var showingAssistant = false
    /// Set when the assistant's citation is tapped, so the sheet can hand off
    /// into the dictionary. Learn has no navigation path to push onto.
    @State private var assistantTopic: LearnTopic?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Topics matching the search text.
    private var filtered: [LearnTopic] {
        let base = LearnContent.all
        let q = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return base }
        return base.filter {
            $0.title.lowercased().contains(q) || $0.whatItIs.lowercased().contains(q)
        }
    }

    /// Searching is the only thing that swaps the layout now. Picking a lens
    /// navigates rather than filtering in place, so there is exactly one control
    /// on this screen that changes what it shows.
    private var isBrowsing: Bool {
        searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    hero
                    searchRow
                    if isBrowsing {
                        lensCards
                    } else {
                        MasonryGrid(topics: filtered, appeared: appeared)
                            .padding(.horizontal, Spacing.xl)
                    }
                    if !isBrowsing && filtered.isEmpty { emptyResults }
                }
                .padding(.top, Spacing.md)
                .padding(.bottom, 120)
            }
            .background(
                AllyBackground()
                    // A tap anywhere off the field puts the keyboard away.
                    // `scrollDismissesKeyboard` only fires on a drag, so a plain
                    // tap on the background used to leave it up with nowhere
                    // obvious to go.
                    .contentShape(Rectangle())
                    .onTapGesture { dismissKeyboard() }
            )
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.immediately)
            .tracksTabBar()
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: AccessibilityCategory.self) { CategoryDetailView(category: $0) }
            .navigationDestination(for: LearnTopic.self) { TopicDetailView(topic: $0) }
            .sheet(isPresented: $showingAssistant) {
                AssistantView { assistantTopic = $0 }
            }
            .sheet(item: $assistantTopic) { topic in
                NavigationStack { TopicDetailView(topic: topic) }
            }
            .onAppear {
                withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : AnimationTokens.spring) {
                    appeared = true
                }
                if CommandLine.arguments.contains("-openAssistant") { showingAssistant = true }
            }
        }
    }

    // MARK: Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("ACCESSIBILITY, MADE TACTILE")
                .font(Typography.eyebrow)
                .foregroundStyle(ColorTokens.brandPrimaryInk)
            HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                Text("Learn")
                    .font(Typography.display)
                    .foregroundStyle(ColorTokens.textPrimary)
                Text("\(LearnContent.all.count)")
                    .font(Typography.footnote.weight(.bold))
                    .foregroundStyle(ColorTokens.onFill(ColorTokens.brandPrimary))
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(ColorTokens.brandPrimary))
                    .accessibilityHidden(true)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Learn, \(LearnContent.all.count) topics")
            .accessibilityAddTraits(.isHeader)

            Text("Look it up, don't finish it.")
                .font(Typography.callout)
                .foregroundStyle(ColorTokens.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.xl)
    }

    // MARK: Search and Ask, side by side

    /// The two ways in, given equal weight. Search assumes you know the word;
    /// Ask is for when you don't, which is most of the time in this subject.
    private var searchRow: some View {
        HStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .bold))
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
            .frame(minHeight: 54)
            .background(Capsule().fill(ColorTokens.surfaceElevated))
            .overlay(Capsule().stroke(ColorTokens.border, lineWidth: 1))

            Button {
                Haptics.selection()
                showingAssistant = true
            } label: {
                Image(systemName: "sparkles")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(ColorTokens.onFill(ColorTokens.brandPrimary))
                    .frame(width: 54, height: 54)
                    .background(Circle().fill(ColorTokens.brandPrimary))
            }
            .buttonStyle(.pressableCard)
            .accessibilityLabel("Ask a question")
            .accessibilityHint("Answers come from Ally's topics, on your iPhone")
        }
        .padding(.horizontal, Spacing.xl)
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }

    // MARK: Browse — the four lenses

    /// Four cards, one per lens, in a two-up bento. Each is a doorway rather
    /// than a preview: the count and the tagline are enough to choose with, and
    /// the topic titles live one level down where there is room for them.
    private var lensCards: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("BROWSE BY WHO IT AFFECTS")
                .font(Typography.eyebrow)
                .foregroundStyle(ColorTokens.textTertiary)
                .padding(.horizontal, Spacing.xl)
                .accessibilityAddTraits(.isHeader)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: Spacing.md),
                                GridItem(.flexible(), spacing: Spacing.md)],
                      spacing: Spacing.md) {
                ForEach(Array(AccessibilityCategory.allCases.enumerated()), id: \.element) { index, category in
                    NavigationLink(value: category) {
                        LensCard(category: category,
                                 count: LearnContent.topics(for: category).count,
                                 tall: index % 3 == 0)
                    }
                    .buttonStyle(.pressableCard)
                    .floating(index)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 26)
                    .animation(reduceMotion ? .easeInOut(duration: 0.2)
                                            : AnimationTokens.spring.delay(Double(index) * 0.08),
                               value: appeared)
                }
            }
            .padding(.horizontal, Spacing.xl)
        }
    }

    private var emptyResults: some View {
        VStack(spacing: Spacing.sm) {
            Text("No topics match “\(searchText)”")
                .font(Typography.headline)
                .foregroundStyle(ColorTokens.textPrimary)
                .multilineTextAlignment(.center)
            Text("Try a different word, or ask a question instead.")
                .font(Typography.subheadline)
                .foregroundStyle(ColorTokens.textSecondary)
                .multilineTextAlignment(.center)
            Button("Ask a question") {
                Haptics.selection()
                showingAssistant = true
            }
            .font(Typography.subheadline.weight(.semibold))
            .foregroundStyle(ColorTokens.onFill(ColorTokens.brandPrimary))
            .padding(.horizontal, Spacing.lg)
            .frame(minHeight: 44)
            .background(Capsule().fill(ColorTokens.brandPrimary))
            .padding(.top, Spacing.xs)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
        .padding(.horizontal, Spacing.xl)
    }
}

// MARK: - Masonry

/// Two columns filled by running height rather than by index, so cards of
/// different heights interlock instead of leaving a ragged gap. `LazyVGrid`
/// can't do this: it aligns rows, which is exactly the grid look being avoided.
private struct MasonryGrid: View {
    let topics: [LearnTopic]
    let appeared: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Heights vary with blurb length so the interlock is content-driven rather
    /// than a random-looking zigzag.
    private func height(for topic: LearnTopic) -> CGFloat {
        topic.whatItIs.count > 62 ? 232 : 198
    }

    private var columns: ([LearnTopic], [LearnTopic]) {
        var left: [LearnTopic] = [], right: [LearnTopic] = []
        var lh: CGFloat = 0, rh: CGFloat = 0
        for t in topics {
            if lh <= rh { left.append(t); lh += height(for: t) }
            else { right.append(t); rh += height(for: t) }
        }
        return (left, right)
    }

    var body: some View {
        let (left, right) = columns
        HStack(alignment: .top, spacing: Spacing.md) {
            column(left, offset: 0)
            column(right, offset: 1)
        }
    }

    private func column(_ items: [LearnTopic], offset: Int) -> some View {
        VStack(spacing: Spacing.md) {
            ForEach(Array(items.enumerated()), id: \.element.id) { i, topic in
                NavigationLink(value: topic) {
                    TopicCard(topic: topic, height: height(for: topic))
                }
                .buttonStyle(.pressableCard)
                .floating(i * 2 + offset, amplitude: 2)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 18)
                .animation(reduceMotion ? .easeInOut(duration: 0.2)
                                        : AnimationTokens.spring.delay(Double(min(i * 2 + offset, 8)) * 0.04),
                           value: appeared)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Cards

/// A whole lens as one card. Deliberately the biggest thing on the screen,
/// because choosing a lens is the only decision Learn asks you to make.
private struct LensCard: View {
    let category: AccessibilityCategory
    let count: Int
    /// Staggered heights so four cards read as a bento rather than a 2x2 table.
    var tall: Bool = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                LivingCategoryArt(category: category, size: tall ? 62 : 54, onCategoryFill: true)
                Spacer(minLength: Spacing.xs)
                Text(category.title)
                    .font(Typography.title3)
                    .foregroundStyle(ColorTokens.ink)
                Text(category.tagline)
                    .font(Typography.footnote)
                    .foregroundStyle(ColorTokens.ink.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(count) topics")
                    .font(Typography.caption2.weight(.bold))
                    .foregroundStyle(ColorTokens.ink)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(ColorTokens.ink.opacity(0.14)))
                    .padding(.top, Spacing.xxs)
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, minHeight: tall ? 232 : 202, alignment: .topLeading)
            .background(NotchedCard(notch: 42).fill(category.color))

            NotchGlyph(systemName: "arrow.up.right", tint: category.inkColor, size: 32)
                .offset(x: 5, y: -5)
        }
        // One element, one sentence. VoiceOver should not have to swipe through
        // four fragments to learn what this card is.
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(category.title). \(category.tagline). \(count) topics.")
        .accessibilityHint("Opens the \(category.title) topics")
    }
}

/// The card used in the search and filter masonry.
private struct TopicCard: View {
    let topic: LearnTopic
    var height: CGFloat = 198

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                LivingCategoryArt(category: topic.category, size: 30, onCategoryFill: true)
                    .padding(.bottom, 2)
                Text(topic.category.title.uppercased())
                    .font(Typography.caption2.weight(.bold))
                    .foregroundStyle(ColorTokens.ink.opacity(0.65))
                Text(topic.title)
                    .font(Typography.headline)
                    .foregroundStyle(ColorTokens.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(topic.whatItIs)
                    .font(Typography.footnote)
                    .foregroundStyle(ColorTokens.ink.opacity(0.75))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: Spacing.xs)
                WCAGPip(ref: topic.wcagRef, tint: ColorTokens.ink.opacity(0.12), text: ColorTokens.ink)
            }
            .padding(Spacing.lg)
            .frame(width: 172, height: height, alignment: .topLeading)
            .background(NotchedCard(notch: 36).fill(topic.category.color))

            NotchGlyph(systemName: "arrow.up.right", tint: topic.category.inkColor, size: 28)
                .offset(x: 4, y: -4)
        }
        .frame(width: 178, height: height + 6, alignment: .topLeading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(topic.title). \(topic.category.title). \(topic.whatItIs)")
        .accessibilityHint("Opens the topic")
    }
}

/// The criterion number, kept deliberately small. Present for people who want
/// the spec, out of the way of people who don't.
private struct WCAGPip: View {
    let ref: String
    let tint: Color
    let text: Color

    var body: some View {
        Text(ref)
            .font(Typography.mono)
            .foregroundStyle(text)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 3)
            .background(Capsule().fill(tint))
    }
}

#Preview { LearnHomeView() }
