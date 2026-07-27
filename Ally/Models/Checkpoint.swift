import Foundation
import SwiftData

/// One answered self-assessment question, keyed to a `CheckpointItem` in the
/// static `CheckpointBank` by `itemID` (which also carries the WCAG criterion).
@Model
final class Checkpoint {
    var itemID: String
    var categoryRaw: String
    var answerRaw: String
    var answeredAt: Date

    var project: Project?

    init(itemID: String, category: AccessibilityCategory, answer: Answer, answeredAt: Date = .now) {
        self.itemID = itemID
        self.categoryRaw = category.rawValue
        self.answerRaw = answer.rawValue
        self.answeredAt = answeredAt
    }

    var category: AccessibilityCategory {
        get { AccessibilityCategory(rawValue: categoryRaw) ?? .vision }
        set { categoryRaw = newValue.rawValue }
    }

    var answer: Answer {
        get { Answer(rawValue: answerRaw) ?? .notSure }
        set { answerRaw = newValue.rawValue }
    }

    /// The four possible responses. `weight` feeds the score; `countsTowardScore`
    /// keeps "Not sure" out of the denominator so an honest "I don't know" doesn't
    /// tank the number — it's surfaced separately as something to revisit.
    enum Answer: String, CaseIterable, Identifiable, Codable {
        case yes = "Yes"
        case partially = "Partially"
        case no = "No"
        case notSure = "Not sure"

        var id: String { rawValue }

        var weight: Double {
            switch self {
            case .yes:       return 1.0
            case .partially: return 0.5
            case .no:        return 0.0
            case .notSure:   return 0.0
            }
        }

        var countsTowardScore: Bool { self != .notSure }
    }
}
