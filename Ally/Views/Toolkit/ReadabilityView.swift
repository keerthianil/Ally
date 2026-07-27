import SwiftUI

/// Paste copy → Flesch-Kincaid grade + reading ease, sentence stats, and jargon
/// flags with plainer suggestions. Live-updates as you type.
struct ReadabilityView: View {
    @State private var text: String =
        "Utilize the aforementioned functionality to facilitate the authentication of your account credentials."

    private var stats: ReadabilityStats { ReadabilityStats.analyze(text) }
    private var jargon: [(word: String, suggestion: String)] { ReadabilityStats.jargonFlags(text) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                editor
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
    }

    private var editor: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("YOUR COPY").font(Typography.eyebrow).foregroundStyle(ColorTokens.textSecondary)
            TextEditor(text: $text)
                .font(Typography.body)
                .frame(minHeight: 120)
                .scrollContentBackground(.hidden)
                .padding(Spacing.md)
                .background(RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous).fill(ColorTokens.surfaceElevated))
                .overlay(RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous).stroke(ColorTokens.border, lineWidth: 0.5))
        }
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
                .font(Typography.headline).foregroundStyle(ColorTokens.warning)
            ForEach(jargon, id: \.word) { entry in
                HStack {
                    Text(entry.word).font(Typography.subheadline.weight(.semibold))
                        .foregroundStyle(ColorTokens.textPrimary)
                    Image(systemName: "arrow.right").font(.system(size: 11)).foregroundStyle(ColorTokens.textTertiary)
                    Text(entry.suggestion).font(Typography.subheadline)
                        .foregroundStyle(ColorTokens.success)
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
struct ReadabilityStats {
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
        case 70...:   return ColorTokens.success
        case 50..<70: return ColorTokens.warning
        default:      return ColorTokens.error
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
