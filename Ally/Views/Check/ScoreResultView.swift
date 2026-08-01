import SwiftUI
import Charts

/// The payoff: animated score ring, per-category breakdown, "what changed since
/// last time," a trend chart, and the prioritized fix-list that deep-links into
/// Learn. Confetti fires when a re-check beats the previous score.
struct ScoreResultView: View {
    @Bindable var project: Project
    var onRecheck: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var confettiTrigger = 0
    @State private var pdfURL: URL?
    @State private var learnTopic: LearnTopic?

    private var result: ScoreEngine.Result { ScoreEngine.result(for: project) }
    private var history: [CheckpointHistory] { project.history.sorted { $0.date < $1.date } }

    private var delta: Int? {
        guard history.count >= 2 else { return nil }
        return history[history.count - 1].score - history[history.count - 2].score
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                ScoreRing(result: result).padding(.top, Spacing.lg)
                if let delta { changePill(delta) }
                breakdown
                if history.count >= 2 { trendChart }
                if !result.needsWork.isEmpty { focusAreas }
                actions
            }
            .padding(Spacing.xl)
            .padding(.bottom, 110)
        }
        .background(AllyBackground(accent: ColorTokens.brandPrimary))
        .scrollIndicators(.hidden)
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.inline)
        .overlay(ConfettiView(trigger: confettiTrigger))
        .sheet(item: $learnTopic) { topic in
            NavigationStack { TopicDetailView(topic: topic) }
        }
        .task {
            pdfURL = PDFReportService.generate(projectName: project.name,
                                               platform: project.platform.rawValue,
                                               result: result)
            if let delta, delta > 0 { celebrate() }
        }
    }

    private func changePill(_ delta: Int) -> some View {
        let up = delta > 0
        return HStack(spacing: Spacing.sm) {
            Image(systemName: up ? "arrow.up.right" : (delta < 0 ? "arrow.down.right" : "equal"))
            Text(delta == 0 ? "No change since last check" :
                    "\(up ? "+" : "")\(delta) since last check")
                .font(Typography.footnote.weight(.bold))
        }
        .foregroundStyle(up ? ColorTokens.success : (delta < 0 ? ColorTokens.error : ColorTokens.textSecondary))
        .padding(.horizontal, Spacing.md).padding(.vertical, Spacing.sm)
        .background(Capsule().fill((up ? ColorTokens.success : ColorTokens.textSecondary).opacity(0.12)))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(delta == 0 ? "No change since last check"
            : "\(up ? "Up" : "Down") \(abs(delta)) points since last check")
    }

    private var breakdown: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("By category").font(Typography.headline)
                .foregroundStyle(ColorTokens.textPrimary).accessibilityAddTraits(.isHeader)
            ForEach(result.byCategory) { cs in
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        Circle().fill(cs.category.inkColor).frame(width: 12, height: 12)
                        Text(cs.category.title).font(Typography.bodyEmph)
                            .foregroundStyle(ColorTokens.textPrimary)
                        Spacer()
                        Text("\(cs.score)").font(Typography.bodyEmph)
                            .foregroundStyle(cs.category.inkColor)
                        if cs.notSure > 0 {
                            Text("· \(cs.notSure) unsure").font(Typography.caption)
                                .foregroundStyle(ColorTokens.textTertiary)
                        }
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(cs.category.color.opacity(0.15))
                            Capsule().fill(cs.category.inkColor)
                                .frame(width: max(6, geo.size.width * CGFloat(cs.score) / 100))
                        }
                    }.frame(height: 8)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(cs.category.title): \(cs.score) out of 100")
            }
        }
        .padding(Spacing.lg)
        .background(card)
    }

    private var trendChart: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Progress over time").font(Typography.headline)
                .foregroundStyle(ColorTokens.textPrimary).accessibilityAddTraits(.isHeader)
            Chart(history) { snap in
                LineMark(x: .value("Date", snap.date), y: .value("Score", snap.score))
                    .foregroundStyle(ColorTokens.brandPrimary)
                    .interpolationMethod(.catmullRom)
                PointMark(x: .value("Date", snap.date), y: .value("Score", snap.score))
                    .foregroundStyle(ColorTokens.brandPrimary)
                AreaMark(x: .value("Date", snap.date), y: .value("Score", snap.score))
                    .foregroundStyle(ColorTokens.brandPrimary.opacity(0.12))
                    .interpolationMethod(.catmullRom)
            }
            .chartYScale(domain: 0...100)
            .frame(height: 160)
        }
        .padding(Spacing.lg)
        .background(card)
    }

    private var focusAreas: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Focus areas").font(Typography.headline)
                .foregroundStyle(ColorTokens.textPrimary).accessibilityAddTraits(.isHeader)
            ForEach(result.needsWork.prefix(6), id: \.item.id) { entry in
                Button {
                    if let id = entry.item.learnTopicID { learnTopic = LearnContent.topic(id: id) }
                } label: {
                    HStack(spacing: Spacing.md) {
                        Text(entry.answer.rawValue)
                            .font(Typography.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, Spacing.sm).padding(.vertical, 3)
                            .background(Capsule().fill(entry.answer == .no ? ColorTokens.error : ColorTokens.warning))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.item.question).font(Typography.subheadline)
                                .foregroundStyle(ColorTokens.textPrimary)
                                .multilineTextAlignment(.leading)
                            Text("WCAG \(entry.item.wcagRef)").font(Typography.caption2)
                                .foregroundStyle(ColorTokens.textTertiary)
                        }
                        Spacer(minLength: 0)
                        if entry.item.learnTopicID != nil {
                            Image(systemName: "arrow.up.forward.square")
                                .foregroundStyle(entry.item.category.inkColor)
                        }
                    }
                    .padding(Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                        .fill(ColorTokens.surface))
                }
                .buttonStyle(.pressableCard)
                .disabled(entry.item.learnTopicID == nil)
                .accessibilityHint(entry.item.learnTopicID != nil ? "Opens the Learn topic" : "")
            }
        }
        .padding(Spacing.lg)
        .background(card)
    }

    private var actions: some View {
        VStack(spacing: Spacing.md) {
            Button { onRecheck() } label: {
                Label("Re-check", systemImage: "arrow.clockwise")
                    .font(Typography.headline).foregroundStyle(ColorTokens.onBrand)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Capsule().fill(ColorTokens.brandPrimary))
            }
            .buttonStyle(.pressableCard)

            if let pdfURL {
                ShareLink(item: pdfURL) {
                    Label("Export PDF report", systemImage: "square.and.arrow.up")
                        .font(Typography.headline).foregroundStyle(ColorTokens.brandPrimaryInk)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Capsule().fill(ColorTokens.brandPrimary.opacity(0.12)))
                }
            }
        }
    }

    private var card: some View {
        RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
            .fill(ColorTokens.surfaceElevated)
            .overlay(RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
                .stroke(ColorTokens.border, lineWidth: 0.5))
    }

    private func celebrate() {
        guard !reduceMotion else { return }
        confettiTrigger += 1
        Haptics.success()
    }
}
