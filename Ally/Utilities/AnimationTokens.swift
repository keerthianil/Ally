import SwiftUI

/// Centralized motion. Every spring/curve the app uses is defined here so timing
/// stays consistent and — critically — so Reduce Motion can be honored in one place.
///
/// Ally teaches vestibular-safe motion (WCAG 2.3.3), so it must obey the system
/// setting itself. Use `AnimationTokens.motion(_:)` / the `.allyAnimation` modifier
/// instead of raw `.animation(...)`: when Reduce Motion is on, springy/parallax
/// animations collapse to a quick crossfade (or nothing).
enum AnimationTokens {

    // MARK: - Springs
    /// Standard UI spring — card reveals, selection, sheet content.
    static let spring = Animation.spring(response: 0.42, dampingFraction: 0.78)
    /// Bouncier — celebratory / playful moments (score reveal, tab pop).
    static let bouncy = Animation.spring(response: 0.5, dampingFraction: 0.62)
    /// Snappy — small immediate feedback (toggles, chips).
    static let snappy = Animation.spring(response: 0.3, dampingFraction: 0.82)

    // MARK: - Curves / durations
    static let quick = Animation.easeInOut(duration: 0.2)
    static let smooth = Animation.easeInOut(duration: 0.35)
    /// Score-ring fill sweep.
    static let ringFill = Animation.easeOut(duration: 1.1)

    /// Reduce-Motion-safe crossfade used as the fallback for any big motion.
    static let reducedFallback = Animation.easeInOut(duration: 0.2)

    /// Returns `animation` normally, or a gentle crossfade when Reduce Motion is on.
    /// Pass `disableEntirely: true` for purely decorative motion that should simply
    /// not happen under Reduce Motion.
    static func motion(_ animation: Animation,
                       reduceMotion: Bool,
                       disableEntirely: Bool = false) -> Animation? {
        guard reduceMotion else { return animation }
        return disableEntirely ? nil : reducedFallback
    }
}

extension View {
    /// Reduce-Motion-aware replacement for `.animation(_:value:)`.
    /// Reads the environment's `accessibilityReduceMotion` and swaps in a crossfade
    /// (or removes the animation) automatically.
    func allyAnimation<V: Equatable>(_ animation: Animation,
                                     value: V,
                                     disableEntirely: Bool = false) -> some View {
        modifier(AllyAnimationModifier(animation: animation,
                                       value: value,
                                       disableEntirely: disableEntirely))
    }
}

private struct AllyAnimationModifier<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let animation: Animation
    let value: V
    let disableEntirely: Bool

    func body(content: Content) -> some View {
        content.animation(
            AnimationTokens.motion(animation,
                                   reduceMotion: reduceMotion,
                                   disableEntirely: disableEntirely),
            value: value
        )
    }
}
