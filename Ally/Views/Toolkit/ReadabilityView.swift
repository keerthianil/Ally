import SwiftUI

/// Paste copy → Flesch-Kincaid grade + reading ease, sentence stats, and jargon
/// flags with plainer suggestions. Live-updates as you type.
///
/// On iOS 26 hardware with Apple Intelligence, it will also propose a full plain
/// -language rewrite. That's strictly additive: the grade, the stats and the
/// jargon list are computed locally with arithmetic and work on every device
/// Ally supports.
struct ReadabilityView: View {
    @State private var text: String =
        "Utilize the aforementioned functionality to facilitate the authentication of your account credentials."

    // MARK: Rewrite state
    @State private var rewrite: PlainLanguageRewriter.Result?
    @State private var rewriteError: PlainLanguageRewriter.Failure?
    @State private var rewriteTask: Task<Void, Never>?
    @State private var isRewriting = false
    @State private var announcement = ""

    private let aiStatus = AllyIntelligence.status

    private var stats: ReadabilityStats { ReadabilityStats.analyze(text) }
    private var jargon: [(word: String, suggestion: String)] { ReadabilityStats.jargonFlags(text) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                intro
                editor
                rewriteSection
                gradeCard
                statRow
                if !jargon.isEmpty { jargonCard }
            }
            .padding(Spacing.xl)
            .padding(.bottom, Spacing.xxl)
        }
        .background(AllyBackground(accent: ColorTokens.cognitive))
        .scrollIndicators(.hidden)
        .navigationTitle("Readability")
        .navigationBarTitleDisplayMode(.inline)
        // Editing invalidates any proposal on screen, and cancels one in flight —
        // otherwise a slow response lands against copy the user has moved on from.
        .onChange(of: text) { _, _ in
            rewriteTask?.cancel()
            isRewriting = false
            rewrite = nil
            rewriteError = nil
        }
        .onDisappear { rewriteTask?.cancel() }
    }

    private var intro: some View {
        Text("Paste any copy, a button label, an onboarding line, an error message, to see how hard it is to read, and get simpler word swaps.")
            .font(Typography.callout)
            .foregroundStyle(ColorTokens.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var editor: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("EDIT YOUR COPY HERE").font(Typography.eyebrow).foregroundStyle(ColorTokens.textSecondary)
            TextEditor(text: $text)
                .font(Typography.body)
                .frame(minHeight: 120)
                .scrollContentBackground(.hidden)
                .padding(Spacing.md)
                .background(RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous).fill(ColorTokens.surfaceElevated))
                .overlay(RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous).stroke(ColorTokens.border, lineWidth: 0.5))
        }
    }

    // MARK: Rewrite

    @ViewBuilder private var rewriteSection: some View {
        if aiStatus.isReady {
            VStack(alignment: .leading, spacing: Spacing.md) {
                if isRewriting {
                    ThinkingIndicator(label: "Rewriting on your iPhone")
                        .padding(.vertical, Spacing.sm)
                } else {
                    rewriteButton
                }
                if let rewrite { proposalCard(rewrite) }
                if let rewriteError { errorNote(rewriteError) }
            }
        } else {
            IntelligenceStatusCard(
                status: aiStatus,
                fallbackNote: "The grade level, the stats and the jargon list below are plain arithmetic, they work on every iPhone."
            )
        }
    }

    private var rewriteButton: some View {
        Button {
            startRewrite()
        } label: {
            Label("Rewrite in plain language", systemImage: "wand.and.sparkles")
                .font(Typography.headline)
                .foregroundStyle(ColorTokens.onBrand)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Capsule().fill(ColorTokens.brandPrimary))
        }
        .buttonStyle(.pressableCard)
        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .accessibilityHint("Suggests a simpler version. Nothing changes until you accept it.")
    }

    /// A *proposal*, never an edit. The user reads it, checks the new grade, and
    /// decides — the whole point of the feature is that judgment stays theirs.
    private func proposalCard(_ result: PlainLanguageRewriter.Result) -> some View {
        let delta = stats.gradeLevel - result.gradeLevel

        return VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                Text("SUGGESTED REWRITE")
                    .font(Typography.eyebrow)
                    .foregroundStyle(ColorTokens.cognitiveInk)
                Spacer()
                Text(gradeDeltaLabel(delta, newGrade: result.gradeLevel))
                    .font(Typography.caption.weight(.bold))
                    .foregroundStyle(delta > 0.05 ? ColorTokens.successInk : ColorTokens.textSecondary)
            }

            Text(result.rewrite)
                .font(Typography.body)
                .foregroundStyle(ColorTokens.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if !result.changes.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    ForEach(result.changes, id: \.self) { change in
                        HStack(alignment: .top, spacing: Spacing.sm) {
                            Text("·").foregroundStyle(ColorTokens.textTertiary)
                            Text(change)
                                .font(Typography.footnote)
                                .foregroundStyle(ColorTokens.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

            HStack(spacing: Spacing.sm) {
                Button {
                    applyRewrite(result)
                } label: {
                    Text("Use this")
                        .font(Typography.subheadline.weight(.semibold))
                        .foregroundStyle(ColorTokens.onBrand)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Capsule().fill(ColorTokens.brandPrimary))
                }
                .buttonStyle(.pressableCard)
                .accessibilityHint("Replaces your copy with the suggestion. You can still edit it.")

                Button {
                    withAnimation(AnimationTokens.snappy) { rewrite = nil }
                    Haptics.light()
                } label: {
                    Text("Dismiss")
                        .font(Typography.subheadline.weight(.semibold))
                        .foregroundStyle(ColorTokens.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Capsule().fill(ColorTokens.surfaceElevated))
                        .overlay(Capsule().stroke(ColorTokens.border, lineWidth: 0.5))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
            .fill(ColorTokens.surfaceElevated))
        .overlay(RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
            .stroke(ColorTokens.cognitive.opacity(0.4), lineWidth: 1))
    }

    /// Measured from the rewrite, not asserted by the model — so it can honestly
    /// report that a suggestion didn't help.
    private func gradeDeltaLabel(_ delta: Double, newGrade: Double) -> String {
        let grade = String(format: "%.1f", newGrade)
        if delta > 0.05 { return "grade \(grade), down \(String(format: "%.1f", delta))" }
        if delta < -0.05 { return "grade \(grade), no simpler" }
        return "grade \(grade)"
    }

    @ViewBuilder private func errorNote(_ failure: PlainLanguageRewriter.Failure) -> some View {
        Text(message(for: failure))
            .font(Typography.footnote)
            .foregroundStyle(ColorTokens.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func message(for failure: PlainLanguageRewriter.Failure) -> String {
        switch failure {
        case .unavailable: return "On-device rewriting isn't available right now. Everything else on this screen still works."
        case .refused:     return "The model declined to rewrite this one. Try rephrasing, or use the jargon swaps below."
        case .failed:      return "That didn't work. Try again, or use the jargon swaps below."
        }
    }

    // MARK: Actions

    private func startRewrite() {
        rewriteTask?.cancel()
        rewriteError = nil
        withAnimation(AnimationTokens.snappy) { isRewriting = true }
        let source = text
        rewriteTask = Task {
            do {
                let result = try await PlainLanguageRewriter.rewrite(source)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    withAnimation(AnimationTokens.spring) {
                        rewrite = result
                        isRewriting = false
                    }
                    Haptics.success()
                    // One announcement when the answer is ready. VoiceOver users
                    // get told it arrived instead of having to go hunting.
                    AccessibilityNotification.Announcement(
                        "Rewrite ready. Reading grade \(String(format: "%.1f", result.gradeLevel))."
                    ).post()
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    withAnimation(AnimationTokens.snappy) {
                        rewriteError = error as? PlainLanguageRewriter.Failure ?? .failed
                        isRewriting = false
                    }
                    Haptics.warning()
                }
            }
        }
    }

    private func applyRewrite(_ result: PlainLanguageRewriter.Result) {
        // Assigning `text` trips the onChange above, which clears the proposal.
        withAnimation(AnimationTokens.spring) { text = result.rewrite }
        Haptics.success()
        AccessibilityNotification.Announcement("Rewrite applied. You can still edit it.").post()
    }

    private var gradeCard: some View {
        HStack(spacing: Spacing.xl) {
            VStack(spacing: 0) {
                Text(stats.words == 0 ? "—" : String(format: "%.1f", stats.gradeLevel))
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundStyle(ColorTokens.textPrimary)
                    .contentTransition(.numericText(value: stats.gradeLevel))
                Text("grade level").font(Typography.caption).foregroundStyle(ColorTokens.textSecondary)
            }
            Divider().frame(height: 48)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(stats.easeLabel).font(Typography.headline)
                    .foregroundStyle(stats.easeColor)
                Text("Reading ease \(stats.words == 0 ? "—" : String(format: "%.0f", stats.readingEase))/100")
                    .font(Typography.footnote).foregroundStyle(ColorTokens.textSecondary)
            }
            Spacer()
        }
        .allyAnimation(AnimationTokens.snappy, value: stats.gradeLevel)
        .padding(Spacing.lg)
        .background(RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous).fill(ColorTokens.surfaceElevated))
    }

    private var statRow: some View {
        HStack(spacing: Spacing.md) {
            stat("\(stats.words)", "words")
            stat("\(stats.sentences)", "sentences")
            stat(stats.sentences == 0 ? "—" : String(format: "%.0f", stats.avgSentenceLength), "avg/sentence")
        }
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(Typography.title3).foregroundStyle(ColorTokens.textPrimary)
            Text(label).font(Typography.caption2).foregroundStyle(ColorTokens.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
        .background(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous).fill(ColorTokens.surfaceElevated))
    }

    private var jargonCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Label("Jargon spotted", systemImage: "exclamationmark.bubble.fill")
                .font(Typography.headline).foregroundStyle(ColorTokens.warningInk)
            ForEach(jargon, id: \.word) { entry in
                HStack {
                    Text(entry.word).font(Typography.subheadline.weight(.semibold))
                        .foregroundStyle(ColorTokens.textPrimary)
                    Image(systemName: "arrow.right").font(.system(size: 11)).foregroundStyle(ColorTokens.textTertiary)
                    Text(entry.suggestion).font(Typography.subheadline)
                        .foregroundStyle(ColorTokens.successInk)
                    Spacer()
                }
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous).fill(ColorTokens.warning.opacity(0.1)))
    }
}

/// Flesch / Flesch-Kincaid with a heuristic syllable counter.
struct ReadabilityStats: Equatable {
    let words: Int
    let sentences: Int
    let syllables: Int

    var avgSentenceLength: Double { sentences == 0 ? 0 : Double(words) / Double(sentences) }
    var avgSyllablesPerWord: Double { words == 0 ? 0 : Double(syllables) / Double(words) }

    var readingEase: Double {
        guard words > 0, sentences > 0 else { return 0 }
        return max(0, min(100, 206.835 - 1.015 * avgSentenceLength - 84.6 * avgSyllablesPerWord))
    }
    var gradeLevel: Double {
        guard words > 0, sentences > 0 else { return 0 }
        return max(0, 0.39 * avgSentenceLength + 11.8 * avgSyllablesPerWord - 15.59)
    }

    var easeLabel: String {
        switch readingEase {
        case 70...:   return "Easy to read"
        case 50..<70: return "Fairly readable"
        default:      return "Hard to read"
        }
    }
    var easeColor: Color {
        switch readingEase {
        case 70...:   return ColorTokens.successInk
        case 50..<70: return ColorTokens.warningInk
        default:      return ColorTokens.errorInk
        }
    }

    static func analyze(_ text: String) -> ReadabilityStats {
        let words = text.split { !$0.isLetter && !$0.isNumber }.map(String.init)
        let sentenceCount = max(text.split { ".!?".contains($0) }
            .filter { $0.contains(where: { $0.isLetter }) }.count, words.isEmpty ? 0 : 1)
        let syll = words.reduce(0) { $0 + syllables(in: $1) }
        return ReadabilityStats(words: words.count, sentences: sentenceCount, syllables: syll)
    }

    static func syllables(in word: String) -> Int {
        let w = word.lowercased()
        guard !w.isEmpty else { return 0 }
        let vowels = Set("aeiouy")
        var count = 0
        var prevVowel = false
        for ch in w {
            let isVowel = vowels.contains(ch)
            if isVowel && !prevVowel { count += 1 }
            prevVowel = isVowel
        }
        if w.hasSuffix("e") { count -= 1 }
        return max(1, count)
    }

    static let dictionary: [String: String] = [
        "utilize": "use", "aforementioned": "above", "functionality": "features",
        "facilitate": "help", "authentication": "sign-in", "credentials": "login",
        "leverage": "use", "commence": "start", "terminate": "end",
        "subsequently": "then", "prior to": "before", "in order to": "to",
        "additional": "more", "assistance": "help", "purchase": "buy",
        "endeavor": "try", "sufficient": "enough", "regarding": "about"
    ]

    static func jargonFlags(_ text: String) -> [(word: String, suggestion: String)] {
        let lower = text.lowercased()
        return dictionary.compactMap { key, value in
            lower.contains(key) ? (key, value) : nil
        }.sorted { $0.0 < $1.0 }
    }
}
