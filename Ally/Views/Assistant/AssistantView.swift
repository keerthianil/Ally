import SwiftUI

/// "Ask Ally" — a small chat over Ally's own corpus.
///
/// Presented as a sheet rather than pushed, because Learn is the one tab driven
/// purely by value-based `NavigationLink` with no path binding, and because a
/// question is a detour from browsing, not a destination.
struct AssistantView: View {
    /// Tapping a citation opens that topic, so an answer is a doorway into the
    /// dictionary rather than a dead end.
    var onOpenTopic: (LearnTopic) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var question = ""
    @State private var turns: [Turn] = []
    @State private var isThinking = false
    @State private var task: Task<Void, Never>?
    @FocusState private var inputFocused: Bool

    private let aiStatus = AllyIntelligence.status

    struct Turn: Identifiable {
        let id = UUID()
        let question: String
        var answer: AllyAssistant.Answer?
        var failure: AllyAssistant.Failure?
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AllyBackground(accent: ColorTokens.cognitive)
                    .ignoresSafeArea()

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: Spacing.xl) {
                            if turns.isEmpty { emptyState }
                            ForEach(turns) { turn in
                                turnView(turn).id(turn.id)
                            }
                            if isThinking {
                                ThinkingIndicator(label: "Looking through Ally's topics")
                                    .id("thinking")
                            }
                        }
                        .padding(Spacing.xl)
                    }
                    .scrollIndicators(.hidden)
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: turns.count) { _, _ in
                        withAnimation(AnimationTokens.spring) {
                            proxy.scrollTo(turns.last?.id, anchor: .bottom)
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) { composer }
            .navigationTitle("Ask Ally")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(Typography.subheadline.weight(.semibold))
                }
            }
            .onDisappear { task?.cancel() }
        }
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Ask about anything in Ally's \(LearnContent.all.count) topics or its WCAG reference. Answers come from those, on your iPhone, and always name their source.")
                .font(Typography.callout)
                .foregroundStyle(ColorTokens.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if !aiStatus.isReady {
                IntelligenceStatusCard(
                    status: aiStatus,
                    fallbackNote: "Learn's search and category filters cover the same \(LearnContent.all.count) topics without it, close this and search there."
                )
            } else {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("TRY ASKING")
                        .font(Typography.eyebrow)
                        .foregroundStyle(ColorTokens.textTertiary)
                    ForEach(Self.suggestions, id: \.self) { s in
                        Button {
                            question = s
                            submit()
                        } label: {
                            HStack {
                                Text(s)
                                    .font(Typography.subheadline)
                                    .foregroundStyle(ColorTokens.textPrimary)
                                    .multilineTextAlignment(.leading)
                                Spacer(minLength: Spacing.sm)
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(ColorTokens.cognitiveInk)
                                    .accessibilityHidden(true)
                            }
                            .padding(Spacing.md)
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                                .fill(ColorTokens.surfaceElevated))
                            .overlay(RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                                .stroke(ColorTokens.border, lineWidth: 0.5))
                        }
                        .buttonStyle(.pressableCard)
                        .accessibilityLabel("Ask: \(s)")
                    }
                }
            }
        }
    }

    private static let suggestions = [
        "How much contrast does body text need?",
        "How big should a tap target be?",
        "What does focus order mean?"
    ]

    // MARK: A question and its answer

    @ViewBuilder private func turnView(_ turn: Turn) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(turn.question)
                .font(Typography.bodyEmph)
                .foregroundStyle(ColorTokens.onFill(ColorTokens.brandPrimaryInk))
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
                .background(RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
                    .fill(ColorTokens.brandPrimaryInk))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .accessibilityLabel("You asked: \(turn.question)")

            if let answer = turn.answer {
                answerView(answer)
            } else if let failure = turn.failure {
                Text(message(for: failure))
                    .font(Typography.subheadline)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func answerView(_ answer: AllyAssistant.Answer) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(answer.text)
                .font(Typography.body)
                .foregroundStyle(ColorTokens.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if let source = answer.source, let topic = source.learnTopicID.flatMap(LearnContent.topic(id:)) {
                Button {
                    dismiss()
                    onOpenTopic(topic)
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: answer.isOutOfScope ? "arrow.turn.down.right" : "book.closed.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text(answer.isOutOfScope ? "Open “\(topic.title)”" : source.title)
                            .font(Typography.caption.weight(.semibold))
                    }
                    .foregroundStyle(topic.category.inkColor)
                    .padding(.horizontal, Spacing.md)
                    .frame(minHeight: 44)
                    .background(Capsule().fill(topic.category.color.opacity(0.14)))
                }
                .buttonStyle(.plain)
                // The chip is the citation *and* the link, so its label has to
                // carry both jobs.
                .accessibilityLabel("Source: \(source.title). Opens the topic.")
            } else if let source = answer.source {
                // A WCAG criterion with no matching Learn topic — still cite it.
                Text(source.title)
                    .font(Typography.caption.weight(.semibold))
                    .foregroundStyle(ColorTokens.textTertiary)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                    .background(Capsule().fill(ColorTokens.surfaceElevated))
                    .accessibilityLabel("Source: \(source.title)")
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
            .fill(ColorTokens.surfaceElevated))
        .overlay(RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
            .stroke(ColorTokens.border, lineWidth: 0.5))
        // One element per answer: VoiceOver reads the answer and its source as a
        // single thought instead of making the user swipe to find the attribution.
        .accessibilityElement(children: .contain)
    }

    private func message(for failure: AllyAssistant.Failure) -> String {
        switch failure {
        case .unavailable: return "I can't answer questions on this iPhone, that needs Apple Intelligence. Learn's search covers the same topics."
        case .refused:     return "I couldn't answer that one. Try rephrasing it."
        case .failed:      return "Something went wrong. Try asking again."
        }
    }

    // MARK: Composer

    /// Hidden entirely when there's no model. An input that can only ever return
    /// "I can't answer that here" is worse than no input — the status card above
    /// has already said so once, calmly, and sends you to Learn's search instead.
    @ViewBuilder private var composer: some View {
        if aiStatus.isReady { composerField }
    }

    private var composerField: some View {
        HStack(spacing: Spacing.sm) {
            TextField("Ask a question", text: $question, axis: .vertical)
                .font(Typography.body)
                .lineLimit(1...4)
                .focused($inputFocused)
                .submitLabel(.send)
                .onSubmit(submit)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .frame(minHeight: 44)
                .background(RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                    .fill(ColorTokens.surfaceElevated))
                .overlay(RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                    .stroke(ColorTokens.border, lineWidth: 0.5))

            Button(action: submit) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(ColorTokens.onBrand)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(ColorTokens.brandPrimary))
            }
            .buttonStyle(.plain)
            .disabled(!canSubmit)
            .opacity(canSubmit ? 1 : 0.4)
            .accessibilityLabel("Ask")
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.md)
        .background(.bar)
    }

    private var canSubmit: Bool {
        !isThinking && !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: Actions

    private func submit() {
        let asked = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !asked.isEmpty, !isThinking else { return }

        question = ""
        inputFocused = false
        let turn = Turn(question: asked)
        withAnimation(AnimationTokens.spring) {
            turns.append(turn)
            isThinking = true
        }
        Haptics.light()

        task?.cancel()
        task = Task {
            do {
                let answer = try await AllyAssistant.answer(to: asked)
                guard !Task.isCancelled else { return }
                await MainActor.run { finish(turn.id, answer: answer, failure: nil) }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    finish(turn.id, answer: nil, failure: error as? AllyAssistant.Failure ?? .failed)
                }
            }
        }
    }

    private func finish(_ id: UUID, answer: AllyAssistant.Answer?, failure: AllyAssistant.Failure?) {
        guard let index = turns.firstIndex(where: { $0.id == id }) else { return }
        withAnimation(AnimationTokens.spring) {
            turns[index].answer = answer
            turns[index].failure = failure
            isThinking = false
        }
        if let answer {
            Haptics.success()
            // A single announcement carrying the answer and its source. Streaming
            // token-by-token into a live region interrupts VoiceOver constantly,
            // so the visible text can stream while this stays one utterance.
            AccessibilityNotification.Announcement(answer.accessibilityText).post()
        } else {
            Haptics.warning()
        }
    }
}

#Preview {
    AssistantView { _ in }
}
