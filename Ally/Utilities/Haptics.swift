import SwiftUI
import UIKit

/// Thin wrapper over `UINotificationFeedbackGenerator` / `UIImpactFeedbackGenerator`
/// for imperative haptics (e.g. inside gesture handlers or completion callbacks).
///
/// For view-driven feedback prefer SwiftUI's native `.sensoryFeedback(_:trigger:)`
/// modifier; use this helper when you need to fire a haptic from non-view code.
enum Haptics {
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
    static func error()   { UINotificationFeedbackGenerator().notificationOccurred(.error) }

    static func light()  { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func medium() { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
    static func rigid()  { UIImpactFeedbackGenerator(style: .rigid).impactOccurred() }
    static func soft()   { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }

    static func selection() { UISelectionFeedbackGenerator().selectionChanged() }
}
