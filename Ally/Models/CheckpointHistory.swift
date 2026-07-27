import Foundation
import SwiftData

/// A frozen score snapshot, written each time the user completes/updates a check.
/// Drives the "what changed since last time" trend (Swift Charts).
@Model
final class CheckpointHistory {
    var date: Date
    var score: Int
    var visionScore: Int
    var motorScore: Int
    var cognitiveScore: Int
    var navigationScore: Int

    var project: Project?

    init(date: Date = .now,
         score: Int,
         visionScore: Int,
         motorScore: Int,
         cognitiveScore: Int,
         navigationScore: Int) {
        self.date = date
        self.score = score
        self.visionScore = visionScore
        self.motorScore = motorScore
        self.cognitiveScore = cognitiveScore
        self.navigationScore = navigationScore
    }

    func score(for category: AccessibilityCategory) -> Int {
        switch category {
        case .vision:     return visionScore
        case .motor:      return motorScore
        case .cognitive:  return cognitiveScore
        case .navigation: return navigationScore
        }
    }
}
