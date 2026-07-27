import Foundation

/// Turns a set of answers into scores. "Not sure" is excluded from the
/// denominator (see `Checkpoint.Answer`) so honesty isn't punished — it's tracked
/// separately as items to revisit.
enum ScoreEngine {

    struct CategoryScore: Identifiable {
        let category: AccessibilityCategory
        let score: Int        // 0–100
        let answered: Int     // counted answers (excludes Not sure)
        let notSure: Int
        let total: Int
        var id: String { category.rawValue }
    }

    struct Result {
        let overall: Int
        let byCategory: [CategoryScore]
        /// Items answered No or Partially, worst first — the "fix these" list.
        let needsWork: [(item: CheckpointItem, answer: Checkpoint.Answer)]

        func score(for category: AccessibilityCategory) -> Int {
            byCategory.first { $0.category == category }?.score ?? 0
        }
    }

    /// Compute from an in-progress answer map (used by the flow).
    static func result(from answers: [String: Checkpoint.Answer]) -> Result {
        var categoryScores: [CategoryScore] = []
        var needsWork: [(CheckpointItem, Checkpoint.Answer)] = []
        var totalWeight = 0.0
        var totalCounted = 0

        for category in AccessibilityCategory.allCases {
            let items = CheckpointBank.items(for: category)
            var weight = 0.0
            var counted = 0
            var notSure = 0
            for item in items {
                guard let answer = answers[item.id] else { continue }
                if answer.countsTowardScore {
                    weight += answer.weight
                    counted += 1
                } else {
                    notSure += 1
                }
                if answer == .no || answer == .partially {
                    needsWork.append((item, answer))
                }
            }
            let score = counted == 0 ? 0 : Int((weight / Double(counted) * 100).rounded())
            categoryScores.append(CategoryScore(category: category, score: score,
                                                answered: counted, notSure: notSure,
                                                total: items.count))
            totalWeight += weight
            totalCounted += counted
        }

        let overall = totalCounted == 0 ? 0 : Int((totalWeight / Double(totalCounted) * 100).rounded())
        // Worst answers first (No before Partially).
        needsWork.sort { a, b in a.1.weight < b.1.weight }
        return Result(overall: overall, byCategory: categoryScores, needsWork: needsWork)
    }

    /// Compute from a persisted project's stored checkpoints.
    static func result(for project: Project) -> Result {
        var answers: [String: Checkpoint.Answer] = [:]
        for cp in project.checkpoints { answers[cp.itemID] = cp.answer }
        return result(from: answers)
    }
}
