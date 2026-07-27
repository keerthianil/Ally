import SwiftUI

/// Button style that makes any card feel physical: it springs down slightly on
/// press and fires a light haptic. Reduce Motion collapses the scale to a subtle
/// opacity dip instead, so the feedback survives without movement.
struct PressableCardStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(reduceMotion ? 1.0 : (configuration.isPressed ? 0.965 : 1.0))
            .opacity(configuration.isPressed && reduceMotion ? 0.85 : 1.0)
            .animation(AnimationTokens.snappy, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed { Haptics.soft() }
            }
    }
}

extension ButtonStyle where Self == PressableCardStyle {
    static var pressableCard: PressableCardStyle { PressableCardStyle() }
}
