import SwiftUI

/// The four lenses Ally organizes everything around — Learn topics, Check
/// checkpoints, and WCAG references all group by these. Keeping one shared enum
/// means a category's color, icon, and copy are defined exactly once.
enum AccessibilityCategory: String, CaseIterable, Identifiable, Codable {
    case vision
    case motor
    case cognitive
    case navigation

    var id: String { rawValue }

    var title: String {
        switch self {
        case .vision:     return "Vision"
        case .motor:      return "Motor"
        case .cognitive:  return "Cognitive"
        case .navigation: return "Navigation"
        }
    }

    /// One-line, plain-English framing of who this lens is about.
    var tagline: String {
        switch self {
        case .vision:     return "Seeing your interface"
        case .motor:      return "Reaching and tapping it"
        case .cognitive:  return "Understanding it"
        case .navigation: return "Moving through it"
        }
    }

    /// Saturated fill color (backgrounds, badges, illustration).
    var color: Color {
        switch self {
        case .vision:     return ColorTokens.vision
        case .motor:      return ColorTokens.motor
        case .cognitive:  return ColorTokens.cognitive
        case .navigation: return ColorTokens.navigation
        }
    }

    /// AA-safe variant for text/links on the app surface.
    var inkColor: Color {
        switch self {
        case .vision:     return ColorTokens.visionInk
        case .motor:      return ColorTokens.motorInk
        case .cognitive:  return ColorTokens.cognitiveInk
        case .navigation: return ColorTokens.navigationInk
        }
    }

    /// SF Symbol placeholder — Learn cards layer custom shapes on top of this.
    var symbol: String {
        switch self {
        case .vision:     return "eye.fill"
        case .motor:      return "hand.tap.fill"
        case .cognitive:  return "brain.head.profile"
        case .navigation: return "location.north.line.fill"
        }
    }
}
