import SwiftUI

/// Searchable, filterable WCAG quick reference grouped by the four POUR
/// principles. Each criterion links back to its Learn entry when one exists.
struct WCAGReferenceView: View {
    @State private var query = ""
    @State private var principleFilter: WCAGCriterion.Principle?
    @State private var learnTopic: LearnTopic?

    private var filtered: [WCAGCriterion] {
        WCAGReference.all.filter { c in
            (principleFilter == nil || c.principle == principleFilter) &&
            (query.isEmpty ||
             c.title.localizedCaseInsensitiveContains(query) ||
             c.id.contains(query) ||
             c.summary.localizedCaseInsensitiveContains(query))
        }
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
                Text("Every WCAG 2.2 criterion Ally covers, in plain words. Search or filter by principle — tap a card with an arrow to open its lesson.")
                    .font(Typography.callout)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                filterRow
                ForEach(grouped, id: \.0) { principle, items in
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(principle.rawValue).font(Typography.title3)
                                .foregroundStyle(ColorTokens.textPrimary)
                                .accessibilityAddTraits(.isHeader)
                            Text(principle.blurb).font(Typography.caption)
                                .foregroundStyle(ColorTokens.textSecondary)
                        }
                        ForEach(items) { criterion in
                            row(criterion)
                        }
                    }
                }
                if filtered.isEmpty {
                    Text("No criteria match “\(query)”.")
                        .font(Typography.callout).foregroundStyle(ColorTokens.textSecondary)
                        .frame(maxWidth: .infinity).padding(.top, Spacing.xl)
                }
            }
            .padding(Spacing.xl)
            .padding(.bottom, Spacing.xxl)
        }
        .background(AllyBackground(accent: ColorTokens.navigation))
        .scrollIndicators(.hidden)
        .searchable(text: $query, prompt: "Search criteria")
        .navigationTitle("WCAG Reference")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $learnTopic) { topic in NavigationStack { TopicDetailView(topic: topic) } }
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                chip("All", principleFilter == nil) { principleFilter = nil }
                ForEach(WCAGCriterion.Principle.allCases) { p in
                    chip(p.rawValue, principleFilter == p) { principleFilter = p }
                }
            }
            .padding(.horizontal, 2)
        }
        .horizontalScrollFade()
    }

    private func chip(_ label: String, _ selected: Bool, _ action: @escaping () -> Void) -> some View {
        Button { action(); Haptics.selection() } label: {
            Text(label).font(Typography.subheadline.weight(.semibold))
                .foregroundStyle(selected ? ColorTokens.onBrand : ColorTokens.textSecondary)
                .padding(.horizontal, Spacing.md).padding(.vertical, Spacing.sm)
                .frame(minHeight: 44)
                .background(Capsule().fill(selected ? ColorTokens.brandPrimary : ColorTokens.surfaceElevated))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }

    private func row(_ c: WCAGCriterion) -> some View {
        Button {
            if let id = c.learnTopicID { learnTopic = LearnContent.topic(id: id) }
        } label: {
            HStack(spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: Spacing.sm) {
                        Text(c.id).font(Typography.mono).foregroundStyle(ColorTokens.brandPrimaryInk)
                        Text(c.level.rawValue).font(Typography.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6).padding(.vertical, 1)
                            .background(Capsule().fill(levelColor(c.level)))
                    }
                    Text(c.title).font(Typography.headline).foregroundStyle(ColorTokens.textPrimary)
                    Text(c.summary).font(Typography.subheadline).foregroundStyle(ColorTokens.textSecondary)
                        .multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                if c.learnTopicID != nil {
                    Image(systemName: "arrow.up.forward.square").foregroundStyle(ColorTokens.brandPrimaryInk)
                }
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous).fill(ColorTokens.surfaceElevated))
            .overlay(RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous).stroke(ColorTokens.border, lineWidth: 0.5))
        }
        .buttonStyle(.pressableCard)
        .disabled(c.learnTopicID == nil)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(c.id) \(c.title), level \(c.level.rawValue). \(c.summary)")
        .accessibilityHint(c.learnTopicID != nil ? "Opens the Learn topic" : "")
    }

    private func levelColor(_ level: WCAGCriterion.Level) -> Color {
        switch level {
        case .a:   return ColorTokens.success
        case .aa:  return ColorTokens.brandSupport
        case .aaa: return ColorTokens.cognitive
        }
    }
}
