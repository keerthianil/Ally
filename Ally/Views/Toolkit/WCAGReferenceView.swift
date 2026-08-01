import SwiftUI

/// A quick reference that behaves like one.
///
/// The previous version was a searchable list, which is a fine *reference* and a
/// poor *quick* reference: you had to read every card to find the one you wanted.
/// The thing you actually arrive knowing is roughly where in POUR your problem
/// sits and roughly how strict you need to be, so those are the two dimensions
/// the screen is built on.
///
/// The map at the top is the whole spec at a glance: four principles, each
/// showing how many criteria it holds and how they split across A, AA and AAA.
/// Tap a principle to drop into it. Nothing here is colour-only, every bar has
/// its number beside it.
struct WCAGReferenceView: View {
    @State private var query = ""
    @State private var principleFilter: WCAGCriterion.Principle?
    @State private var levelFilter: WCAGCriterion.Level?
    @State private var learnTopic: LearnTopic?
    @FocusState private var searchFocused: Bool

    private var filtered: [WCAGCriterion] {
        WCAGReference.all.filter { c in
            (principleFilter == nil || c.principle == principleFilter) &&
            (levelFilter == nil || c.level == levelFilter) &&
            (query.isEmpty ||
             c.title.localizedCaseInsensitiveContains(query) ||
             c.id.contains(query) ||
             c.summary.localizedCaseInsensitiveContains(query))
        }
    }

    private var isFiltering: Bool {
        principleFilter != nil || levelFilter != nil || !query.isEmpty
    }

    private var grouped: [(WCAGCriterion.Principle, [WCAGCriterion])] {
        WCAGCriterion.Principle.allCases.compactMap { p in
            let items = filtered.filter { $0.principle == p }
            return items.isEmpty ? nil : (p, items)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                intro
                searchField
                if !isFiltering { principleMap }
                levelRow
                if isFiltering { activeFilterBar }

                ForEach(grouped, id: \.0) { principle, items in
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack(spacing: Spacing.sm) {
                            Circle().fill(color(for: principle)).frame(width: 10, height: 10)
                                .accessibilityHidden(true)
                            Text(principle.rawValue).font(Typography.title3)
                                .foregroundStyle(ColorTokens.textPrimary)
                            Text("\(items.count)").font(Typography.caption.weight(.bold))
                                .foregroundStyle(ColorTokens.textSecondary)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(principle.rawValue), \(items.count) criteria")
                        .accessibilityAddTraits(.isHeader)

                        ForEach(items) { row($0) }
                    }
                }

                if filtered.isEmpty { emptyState }
            }
            .padding(Spacing.xl)
            .padding(.bottom, Spacing.xxxl)
        }
        .background(
            AllyBackground(accent: ColorTokens.navigation)
                .contentShape(Rectangle())
                .onTapGesture { searchFocused = false }
        )
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle("WCAG Reference")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $learnTopic) { topic in NavigationStack { TopicDetailView(topic: topic) } }
    }

    private var intro: some View {
        Text("The \(WCAGReference.all.count) criteria Ally covers, in plain words. Start from the shape of the spec, then narrow.")
            .font(Typography.callout)
            .foregroundStyle(ColorTokens.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: Search

    private var searchField: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(ColorTokens.textTertiary)
                .accessibilityHidden(true)
            TextField("Search criteria, or type a number", text: $query)
                .font(Typography.body)
                .focused($searchFocused)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(.search)
            if !query.isEmpty {
                Button {
                    withAnimation(AnimationTokens.snappy) { query = "" }
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
        .background(Capsule().fill(ColorTokens.surfaceElevated))
        .overlay(Capsule().stroke(ColorTokens.border, lineWidth: 1))
    }

    // MARK: The map

    /// Four principles, each with its A/AA/AAA split drawn as a stacked bar.
    /// This is the "quick" part: it answers "where does my problem live and how
    /// strict is that area" before you read a single criterion.
    private var principleMap: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("THE SPEC AT A GLANCE")
                .font(Typography.eyebrow)
                .foregroundStyle(ColorTokens.textTertiary)
                .accessibilityAddTraits(.isHeader)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: Spacing.md),
                                GridItem(.flexible(), spacing: Spacing.md)],
                      spacing: Spacing.md) {
                ForEach(Array(WCAGCriterion.Principle.allCases.enumerated()), id: \.element) { i, p in
                    PrincipleCard(principle: p,
                                  criteria: WCAGReference.criteria(for: p),
                                  tint: color(for: p)) {
                        Haptics.selection()
                        withAnimation(AnimationTokens.snappy) { principleFilter = p }
                    }
                    .floating(i, amplitude: 2)
                }
            }
        }
    }

    // MARK: Level

    /// Conformance level, the other thing you arrive knowing. AA is the level
    /// almost every policy actually requires, so it is labelled rather than
    /// left as a bare letter that means nothing until you already know.
    private var levelRow: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("HOW STRICT")
                .font(Typography.eyebrow)
                .foregroundStyle(ColorTokens.textTertiary)
                .accessibilityAddTraits(.isHeader)
            HStack(spacing: Spacing.sm) {
                levelChip(nil, "All", "\(WCAGReference.all.count)")
                ForEach(WCAGCriterion.Level.allCases) { l in
                    levelChip(l, l == .aa ? "AA · the bar" : "Level \(l.rawValue)",
                              "\(WCAGReference.all.filter { $0.level == l }.count)")
                }
            }
        }
    }

    private func levelChip(_ level: WCAGCriterion.Level?, _ label: String, _ count: String) -> some View {
        let selected = levelFilter == level
        let tint = level.map(levelColor) ?? ColorTokens.brandPrimaryInk
        return Button {
            Haptics.selection()
            withAnimation(AnimationTokens.snappy) { levelFilter = selected ? nil : level }
        } label: {
            VStack(spacing: 1) {
                Text(count).font(Typography.subheadline.weight(.bold))
                Text(label).font(Typography.caption2)
                    .lineLimit(1).minimumScaleFactor(0.7)
            }
            .foregroundStyle(selected ? ColorTokens.onFill(tint) : ColorTokens.textSecondary)
            .padding(.horizontal, Spacing.sm)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                .fill(selected ? tint : ColorTokens.surfaceElevated))
            .overlay(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                .stroke(selected ? Color.clear : ColorTokens.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label), \(count) criteria")
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: Active filters

    private var activeFilterBar: some View {
        HStack(spacing: Spacing.sm) {
            Text("\(filtered.count) of \(WCAGReference.all.count)")
                .font(Typography.footnote.weight(.semibold))
                .foregroundStyle(ColorTokens.textSecondary)
            Spacer()
            Button {
                Haptics.light()
                withAnimation(AnimationTokens.snappy) {
                    principleFilter = nil; levelFilter = nil; query = ""
                }
                searchFocused = false
            } label: {
                Label("Clear", systemImage: "xmark")
                    .font(Typography.footnote.weight(.semibold))
                    .foregroundStyle(ColorTokens.brandPrimaryInk)
                    .padding(.horizontal, Spacing.md)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.xs) {
            Text("Nothing matches that")
                .font(Typography.headline).foregroundStyle(ColorTokens.textPrimary)
            Text("Ally covers \(WCAGReference.all.count) of the criteria, not all of WCAG. Try a broader word.")
                .font(Typography.subheadline).foregroundStyle(ColorTokens.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }

    // MARK: Criterion row

    private func row(_ c: WCAGCriterion) -> some View {
        Button {
            if let id = c.learnTopicID { learnTopic = LearnContent.topic(id: id) }
        } label: {
            HStack(alignment: .top, spacing: Spacing.md) {
                // The number is the thing people scan for, so it leads and it is
                // monospaced: a column of aligned digits is far faster to skim
                // than the same numbers set in the body face.
                VStack(spacing: 4) {
                    Text(c.id)
                        .font(Typography.mono)
                        .foregroundStyle(ColorTokens.textPrimary)
                    Text(c.level.rawValue)
                        .font(Typography.caption2.weight(.bold))
                        .foregroundStyle(ColorTokens.onFill(levelColor(c.level)))
                        .padding(.horizontal, 7).padding(.vertical, 2)
                        .background(Capsule().fill(levelColor(c.level)))
                }
                .frame(width: 56)

                VStack(alignment: .leading, spacing: 3) {
                    Text(c.title).font(Typography.headline)
                        .foregroundStyle(ColorTokens.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(c.summary).font(Typography.subheadline)
                        .foregroundStyle(ColorTokens.textSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                if c.learnTopicID != nil {
                    Image(systemName: "arrow.up.forward")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(ColorTokens.brandPrimaryInk)
                        .accessibilityHidden(true)
                }
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
                .fill(ColorTokens.surfaceElevated))
            .overlay(RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
                .stroke(ColorTokens.border, lineWidth: 1))
        }
        .buttonStyle(.pressableCard)
        .disabled(c.learnTopicID == nil)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(c.id) \(c.title), level \(c.level.rawValue). \(c.summary)")
        .accessibilityHint(c.learnTopicID != nil ? "Opens the Learn topic" : "")
    }

    // MARK: Colour

    private func color(for p: WCAGCriterion.Principle) -> Color {
        switch p {
        case .perceivable:    return ColorTokens.vision
        case .operable:       return ColorTokens.motor
        case .understandable: return ColorTokens.cognitive
        case .robust:         return ColorTokens.navigation
        }
    }

    private func levelColor(_ level: WCAGCriterion.Level) -> Color {
        switch level {
        case .a:   return ColorTokens.successInk
        case .aa:  return ColorTokens.brandSupportInk
        case .aaa: return ColorTokens.cognitiveInk
        }
    }
}

// MARK: - Principle card

/// One POUR principle, with its A/AA/AAA split as a stacked bar.
private struct PrincipleCard: View {
    let principle: WCAGCriterion.Principle
    let criteria: [WCAGCriterion]
    let tint: Color
    var onTap: () -> Void

    private var counts: [(WCAGCriterion.Level, Int)] {
        WCAGCriterion.Level.allCases.map { l in (l, criteria.filter { $0.level == l }.count) }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(principle.rawValue)
                    .font(Typography.headline)
                    .foregroundStyle(ColorTokens.ink)
                Text(principle.blurb)
                    .font(Typography.caption)
                    .foregroundStyle(ColorTokens.ink.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: Spacing.xs)

                // The split, drawn to scale. Bars are never the only channel:
                // the counts sit right underneath in text.
                GeometryReader { geo in
                    HStack(spacing: 2) {
                        ForEach(counts, id: \.0) { level, n in
                            if n > 0 {
                                Capsule()
                                    .fill(ColorTokens.ink.opacity(opacity(for: level)))
                                    .frame(width: max(6, geo.size.width * CGFloat(n) / CGFloat(max(criteria.count, 1))))
                            }
                        }
                    }
                }
                .frame(height: 8)

                Text(counts.filter { $0.1 > 0 }.map { "\($0.1) \($0.0.rawValue)" }.joined(separator: " · "))
                    .font(Typography.caption2.weight(.semibold))
                    .foregroundStyle(ColorTokens.ink.opacity(0.8))
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, minHeight: 152, alignment: .topLeading)
            .background(NotchedCard(notch: 34).fill(tint))
            .overlay(alignment: .topTrailing) {
                NotchGlyph(systemName: "line.3.horizontal.decrease", tint: ColorTokens.ink, size: 28)
                    .offset(x: 2, y: -2)
            }
        }
        .buttonStyle(.pressableCard)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(principle.rawValue). \(principle.blurb) \(criteria.count) criteria: \(counts.filter { $0.1 > 0 }.map { "\($0.1) level \($0.0.rawValue)" }.joined(separator: ", ")).")
        .accessibilityHint("Filters to this principle")
    }

    /// Three steps of the same ink rather than three hues, so the bar reads as
    /// one quantity split three ways instead of three unrelated things.
    private func opacity(for level: WCAGCriterion.Level) -> Double {
        switch level {
        case .a:   return 0.85
        case .aa:  return 0.55
        case .aaa: return 0.28
        }
    }
}
