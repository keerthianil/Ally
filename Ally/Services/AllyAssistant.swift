import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Answers accessibility questions from Ally's own corpus, on device.
///
/// The shape is retrieve-then-generate, and the order matters. `AssistantCorpus`
/// decides what the model is allowed to see; the model's only job is to phrase an
/// answer from those passages. It never answers from training data, so it can't
/// invent a WCAG threshold — and the out-of-scope refusal is a retrieval result,
/// not a model instruction, so no phrasing of a question can get around it.
///
/// Every answer names the passage it came from, in the accessibility label as
/// well as the visible chip, and the citation is tappable through to the topic.
enum AllyAssistant {

    struct Answer: Equatable {
        let text: String
        /// The passage backing the answer. Nil only for an unsupported-state message.
        let source: AssistantCorpus.Passage?
        /// True when the question fell outside the corpus; `source` is then the
        /// nearest thing Ally does cover, offered as a suggestion.
        let isOutOfScope: Bool

        /// Read to VoiceOver as one utterance, citation included — the source
        /// isn't decoration, so it shouldn't be visual-only.
        var accessibilityText: String {
            guard let source else { return text }
            return isOutOfScope ? text : "\(text) Source: \(source.title)."
        }
    }

    enum Failure: Error { case unavailable, refused, failed }

    static func answer(to question: String) async throws -> Answer {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw Failure.failed }

        // Retrieval first — before any availability check, so the refusal path is
        // identical on every device and doesn't depend on having a model at all.
        guard let passages = AssistantCorpus.groundingPassages(for: trimmed) else {
            return outOfScopeAnswer(for: trimmed)
        }

        guard AllyIntelligence.status.isReady else { throw Failure.unavailable }

        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let session = LanguageModelSession(instructions: Self.instructions)
            do {
                let response = try await session.respond(
                    to: prompt(question: trimmed, passages: passages),
                    generating: GroundedAnswer.self
                )
                let value = response.content
                let text = HouseStyle.clean(value.answer)
                guard !text.isEmpty else { throw Failure.failed }

                // Trust the retrieval, not the model, for attribution: if it cites
                // an id that wasn't in the prompt, fall back to the top passage
                // rather than showing a citation that doesn't exist.
                let cited = passages.first { $0.id == value.sourceID } ?? passages[0]
                return Answer(text: text, source: cited, isOutOfScope: false)
            } catch let error as LanguageModelSession.GenerationError {
                if case .guardrailViolation = error { throw Failure.refused }
                throw Failure.failed
            } catch {
                throw Failure.failed
            }
        }
        #endif
        throw Failure.unavailable
    }

    /// Retrieval found nothing close enough. Say so, and point at the nearest
    /// real topic instead of guessing.
    private static func outOfScopeAnswer(for question: String) -> Answer {
        if let nearest = AssistantCorpus.nearest(to: question) {
            return Answer(
                text: "I don't cover that. I only answer from Ally's own topics and its WCAG reference, and the closest thing I have is “\(nearest.title)”.",
                source: nearest,
                isOutOfScope: true
            )
        }
        return Answer(
            text: "I don't cover that. I only answer from Ally's \(LearnContent.all.count) topics and its WCAG quick reference, so try asking about contrast, touch targets, labels, or focus order.",
            source: nil,
            isOutOfScope: true
        )
    }

    // MARK: Prompting

    private static let instructions: String = """
        You answer accessibility questions for designers and developers, using \
        ONLY the reference passages given to you in each prompt.

        Rules:
        - Answer only from the passages. You have no other knowledge of accessibility.
        - If the passages do not contain the answer, say so plainly. Do not guess, \
        and never invent a WCAG number, ratio, or size that is not in the passages.
        - Two or three sentences. Plain English, no jargon, no bullet lists.
        - Speak to the reader as "you". Be warm and direct, never scolding.
        - Do not mention "the passages", "the context", or that you were given \
        reference material. Just answer.
        - Set sourceID to the id of the passage you leaned on most.

        \(HouseStyle.voiceRules)
        """

    private static func prompt(question: String, passages: [AssistantCorpus.Passage]) -> String {
        let context = passages.map { "--- id: \($0.id)\n\($0.body)" }.joined(separator: "\n\n")
        return """
            Reference passages:

            \(context)

            ---
            Question: \(question)
            """
    }
}

#if canImport(FoundationModels)
@available(iOS 26.0, *)
@Generable
struct GroundedAnswer {
    @Guide(description: "Two or three plain-English sentences answering the question using only the reference passages.")
    var answer: String

    @Guide(description: "The exact id of the reference passage the answer leans on most, copied verbatim.")
    var sourceID: String
}
#endif
