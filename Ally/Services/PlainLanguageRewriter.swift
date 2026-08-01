import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Rewrites interface copy into plainer language, on device.
///
/// This sits behind WCAG 3.1.5 (Reading Level), which the Toolkit already
/// measures with Flesch-Kincaid. Measuring tells you a sentence is too hard;
/// it doesn't tell you what to write instead. The 18-word jargon dictionary was
/// the previous answer and it can only swap single words — it can't shorten a
/// sentence, unwind a passive, or drop a clause.
///
/// Two rules the product guardrails impose, and this honors:
/// - **Nothing is applied automatically.** The result is a proposal the user
///   accepts, edits, or throws away. Ally never silently rewrites your work.
/// - **Nothing leaves the device.** The text is someone's unshipped product copy.
enum PlainLanguageRewriter {

    struct Result: Equatable {
        let rewrite: String
        let changes: [String]
        /// Recomputed from the rewrite, not claimed by the model. If the model
        /// produced something *harder* to read, the UI should be able to say so.
        let stats: ReadabilityStats

        var gradeLevel: Double { stats.gradeLevel }
    }

    enum Failure: Error {
        case unavailable
        case refused
        case failed
    }

    /// Longer than this and the request isn't interface copy any more — it's a
    /// document, and both the latency and the context window make it a bad fit.
    static let characterLimit = 1_200

    static func rewrite(_ text: String) async throws -> Result {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw Failure.failed }
        guard AllyIntelligence.status.isReady else { throw Failure.unavailable }

        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let session = LanguageModelSession(instructions: Self.instructions)
            do {
                let response = try await session.respond(
                    to: "Rewrite this interface copy:\n\n\(String(trimmed.prefix(characterLimit)))",
                    generating: PlainRewrite.self
                )
                let value = response.content
                let cleaned = HouseStyle.clean(value.rewrite)
                guard !cleaned.isEmpty else { throw Failure.failed }
                return Result(rewrite: cleaned,
                              changes: value.changes.map(HouseStyle.clean).filter { !$0.isEmpty },
                              stats: ReadabilityStats.analyze(cleaned))
            } catch let error as LanguageModelSession.GenerationError {
                // Guardrails fire on text the model won't touch. That's a refusal,
                // not a crash, and the UI says so plainly.
                if case .guardrailViolation = error { throw Failure.refused }
                throw Failure.failed
            } catch {
                throw Failure.failed
            }
        }
        #endif
        throw Failure.unavailable
    }

    /// Constrained hard, because an unconstrained "make this simpler" reliably
    /// returns something shorter that means something different — which for
    /// error messages and button labels is worse than the jargon.
    private static let instructions: String = """
        You rewrite user-interface copy so more people can understand it. You are \
        helping a designer meet WCAG 3.1.5 (Reading Level).

        Rules:
        - Keep the exact meaning. Never add information, and never drop a caveat, \
        a number, a name, or a warning.
        - Prefer short common words and short sentences. Use the active voice.
        - Keep it roughly the same length or shorter. Never pad.
        - Keep the original tone. If it is a button label, it stays a button label.
        - Do not add greetings, apologies, emoji, or commentary.
        - If the text is already plain, return it close to unchanged and say so.

        \(HouseStyle.voiceRules)
        """
}

#if canImport(FoundationModels)
@available(iOS 26.0, *)
@Generable
struct PlainRewrite {
    @Guide(description: "The rewritten copy. Same meaning, plainer words, shorter sentences. Text only, no quotes or labels.")
    var rewrite: String

    @Guide(description: "Short phrases naming what was simplified, e.g. 'utilize became use' or 'split one long sentence in two'.", .count(2...4))
    var changes: [String]
}
#endif
