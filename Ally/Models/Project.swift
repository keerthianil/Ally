import Foundation
import SwiftData

/// A thing the user is assessing — an app, a screen, a website. Owns its
/// checkpoint answers and a history of past scores for the trend chart.
@Model
final class Project {
    var name: String
    var platformRaw: String
    var createdAt: Date
    var updatedAt: Date

    /// Answered checkpoints. Deleting the project deletes its answers.
    @Relationship(deleteRule: .cascade, inverse: \Checkpoint.project)
    var checkpoints: [Checkpoint] = []

    /// One snapshot per completed check, oldest → newest.
    @Relationship(deleteRule: .cascade, inverse: \CheckpointHistory.project)
    var history: [CheckpointHistory] = []

    init(name: String, platform: Platform = .iOS, createdAt: Date = .now) {
        self.name = name
        self.platformRaw = platform.rawValue
        self.createdAt = createdAt
        self.updatedAt = createdAt
    }

    var platform: Platform {
        get { Platform(rawValue: platformRaw) ?? .iOS }
        set { platformRaw = newValue.rawValue }
    }

    enum Platform: String, CaseIterable, Identifiable, Codable {
        case iOS = "iOS"
        case android = "Android"
        case web = "Web"
        case other = "Other"

        var id: String { rawValue }
        var symbol: String {
            switch self {
            case .iOS:     return "apple.logo"
            case .android: return "smartphone"
            case .web:     return "globe"
            case .other:   return "square.stack.3d.up"
            }
        }
    }
}
