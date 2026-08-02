import SwiftUI
import SwiftData

/// Guided assessment — one plain-English question at a time, grouped by category,
/// with a progress bar and four scored answers. On finish it persists the answers
/// and a history snapshot, then hands control back to show the result.
struct CheckpointFlowView: View {
    @Bindable var project: Project
    var onComplete: () -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var index = 0
    @State private var answers: [String: Checkpoint.Answer] = [:]

    private let items = CheckpointBank.all

    private var current: CheckpointItem { items[index] }
    private var progress: Double { Double(index) / Double(items.count) }

    var body: some View {
        VStack(spacing: Spacing.xl) {
            progressHeader

            Spacer(minLength: 0)

            questionCard
                .id(current.id) // drive the transition
                .transition(reduceMotion
                    ? .opacity
                    : .asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                  removal: .move(edge: .leading).combined(with: .opacity)))

            Spacer(minLength: 0)

            answerButtons
        }
        .padding(Spacing.xl)
        .padding(.bottom, Spacing.lg)
        .background(AllyBackground(accent: current.category.color))
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(project.name)
        // Sits on the *trailing* side, and is not a chevron. Next to the system
        // back button it used to read as two identical back arrows, one of which
        // silently left the whole flow. Different glyph, different side, and a
        // visible word, so Voice Control can name it too (WCAG 2.5.3).
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if index > 0 {
                    Button { goBack() } label: {
                        Label("Previous", systemImage: "arrow.uturn.backward")
                            .labelStyle(.titleAndIcon)
                            .font(Typography.footnote.weight(.semibold))
                    }
                    .accessibilityLabel("Previous question")
                    .accessibilityHint("Goes back one question without leaving the check")
                }
            }
        }
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text(current.category.title.uppercased())
                    .font(Typography.eyebrow)
                    .foregroundStyle(current.category.inkColor)
                Spacer()
                Text("\(index + 1) of \(items.count)")
                    .font(Typography.footnote.weight(.semibold))
                    .foregroundStyle(ColorTokens.textSecondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(ColorTokens.border.opacity(0.4))
                    Capsule().fill(current.category.color)
                        .frame(width: max(8, geo.size.width * progress))
                        .allyAnimation(AnimationTokens.spring, value: index)
                }
            }
            .frame(height: 8)
            .accessibilityElement()
            .accessibilityLabel("Question \(index + 1) of \(items.count)")
        }
    }

    private var questionCard: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            CategoryIllustration(category: current.category, size: 72)
            Text(current.question)
                .font(Typography.title1)
                .foregroundStyle(ColorTokens.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Text(current.helper)
                .font(Typography.callout)
                .foregroundStyle(ColorTokens.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: Spacing.xs) {
                Image(systemName: "book.closed.fill").font(.system(size: 11))
                Text("WCAG \(current.wcagRef) · \(current.wcagTitle)")
                    .font(Typography.caption)
            }
            .foregroundStyle(ColorTokens.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var answerButtons: some View {
        VStack(spacing: Spacing.sm) {
            answerButton(.yes, ColorTokens.success, ColorTokens.successInk, "checkmark.circle.fill")
            answerButton(.partially, ColorTokens.warning, ColorTokens.warningInk, "circle.lefthalf.filled")
            answerButton(.no, ColorTokens.error, ColorTokens.errorInk, "xmark.circle.fill")
            answerButton(.notSure, ColorTokens.textSecondary, ColorTokens.textSecondary, "questionmark.circle.fill")
        }
    }

    /// `fill` paints the selected state; `ink` is the same hue darkened enough to
    /// be read as text on the tinted background. They can't be the same value —
    /// emerald reads at 2.12:1 and amber at 1.99:1 against the app surface.
    private func answerButton(_ answer: Checkpoint.Answer, _ fill: Color,
                              _ ink: Color, _ icon: String) -> some View {
        let chosen = answers[current.id] == answer
        return Button {
            select(answer)
        } label: {
            HStack(spacing: Spacing.md) {
                Image(systemName: icon).font(.system(size: 20, weight: .semibold))
                Text(answer.rawValue).font(Typography.headline)
                Spacer()
                if chosen { Image(systemName: "arrow.right").font(.system(size: 15, weight: .bold)) }
            }
            .foregroundStyle(chosen ? ColorTokens.onFill(fill) : ink)
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                .fill(chosen ? fill : fill.opacity(0.12)))
        }
        .buttonStyle(.pressableCard)
        .accessibilityHint("Answer \(answer.rawValue)")
    }

    // MARK: Actions

    private func select(_ answer: Checkpoint.Answer) {
        answers[current.id] = answer
        Haptics.light()
        if index < items.count - 1 {
            withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : AnimationTokens.spring) {
                index += 1
            }
        } else {
            finish()
        }
    }

    private func goBack() {
        guard index > 0 else { return }
        withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : AnimationTokens.spring) {
            index -= 1
        }
    }

    private func finish() {
        let result = ScoreEngine.result(from: answers)

        // Replace stored answers.
        for old in project.checkpoints { context.delete(old) }
        project.checkpoints.removeAll()
        for item in items {
            guard let ans = answers[item.id] else { continue }
            let cp = Checkpoint(itemID: item.id, category: item.category, answer: ans)
            cp.project = project
            project.checkpoints.append(cp)
            context.insert(cp)
        }

        // Append a history snapshot.
        let snapshot = CheckpointHistory(
            score: result.overall,
            visionScore: result.score(for: .vision),
            motorScore: result.score(for: .motor),
            cognitiveScore: result.score(for: .cognitive),
            navigationScore: result.score(for: .navigation))
        snapshot.project = project
        project.history.append(snapshot)
        context.insert(snapshot)

        project.updatedAt = .now
        try? context.save()
        Haptics.success()
        onComplete()
    }
}
