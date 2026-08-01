import SwiftUI

/// Drives the floating tab bar's collapse-on-scroll behaviour.
///
/// The bar **minimises, it never hides**, and for this app that is a position
/// rather than a preference. Apple's own iOS 26 answer (`tabBarMinimizeBehavior`,
/// which only exists for `TabView` and so is unavailable to a hand-rolled bar)
/// collapses to a pill showing the current tab rather than removing it, and the
/// HIG still says to keep the bar visible because people forget where they are
/// without it.
///
/// Three accessibility failures come from hiding it outright, and Ally would be
/// teaching against itself:
/// - **Motor.** A target that vanishes mid-reach is the classic failure for
///   someone with a tremor or slow deliberate pointing.
/// - **Switch Control and Voice Control.** A bar that is not on screen is not in
///   the scan set and cannot be named. That is a hard blocker.
/// - **Cognitive.** The bar is the "you are here" indicator, not just navigation.
///
/// So: collapse to a smaller pill, keep it tappable, and stay fully expanded
/// whenever an assistive technology is on.
@Observable
final class TabBarVisibility {
    private(set) var isCollapsed = false

    private var lastOffset: CGFloat = 0
    private var accumulated: CGFloat = 0

    /// Asymmetric on purpose. Slow to collapse so a stray flick does not do it,
    /// instant to expand because re-showing is cheap and hiding is expensive.
    private let collapseThreshold: CGFloat = 64
    private let expandThreshold: CGFloat = 12
    /// Never collapse near the top: there is no content being obscured yet.
    private let topGuard: CGFloat = 110

    func update(offset: CGFloat, contentHeight: CGFloat, viewportHeight: CGFloat, locked: Bool) {
        // Assistive tech, Reduce Motion, or content that barely scrolls: stay put.
        guard !locked, contentHeight > viewportHeight * 1.4 else {
            set(false); return
        }
        // Rubber-band overscroll produces large fake deltas at both ends.
        let maxOffset = max(0, contentHeight - viewportHeight)
        guard offset >= 0, offset <= maxOffset else { return }

        if offset < topGuard {
            set(false); lastOffset = offset; accumulated = 0; return
        }

        let delta = offset - lastOffset
        lastOffset = offset
        // Reset the run whenever direction flips, so the thresholds measure a
        // single continuous gesture rather than net travel.
        if (delta > 0) != (accumulated > 0) { accumulated = 0 }
        accumulated += delta

        if accumulated > collapseThreshold {
            set(true); accumulated = 0
        } else if accumulated < -expandThreshold {
            set(false); accumulated = 0
        }
    }

    /// Tapping the collapsed pill expands it, so reaching the other tabs never
    /// requires scrolling back up first.
    func expand() { set(false) }

    func reset() { set(false); lastOffset = 0; accumulated = 0 }

    private func set(_ value: Bool) {
        // Deduping matters: assigning the same value inside `withAnimation`
        // restarts the spring every frame, which is what makes hand-rolled
        // versions of this feel broken.
        guard value != isCollapsed else { return }
        withAnimation(.smooth(duration: 0.28)) { isCollapsed = value }
    }
}

private struct TabBarVisibilityKey: EnvironmentKey {
    static let defaultValue = TabBarVisibility()
}

extension EnvironmentValues {
    var tabBarVisibility: TabBarVisibility {
        get { self[TabBarVisibilityKey.self] }
        set { self[TabBarVisibilityKey.self] = newValue }
    }
}

// MARK: - Scroll tracking

extension View {
    /// Report this scroll view's geometry to the floating tab bar.
    ///
    /// Applied to each tab's root `ScrollView`. On iOS 17 the required geometry
    /// API does not exist, so the bar simply stays expanded, which is the safe
    /// degradation rather than a broken one.
    func tracksTabBar() -> some View {
        modifier(TabBarScrollTracker())
    }
}

private struct TabBarScrollTracker: ViewModifier {
    @Environment(\.tabBarVisibility) private var visibility
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @Environment(\.accessibilitySwitchControlEnabled) private var switchControl

    /// Voice Control has no SwiftUI environment value, so it is read straight
    /// from UIKit. It is the case most likely to be forgotten and the one where
    /// a missing on-screen control is least recoverable.
    private var voiceControl: Bool { UIAccessibility.isVoiceOverRunning || UIAccessibility.isSwitchControlRunning }

    private var locked: Bool { reduceMotion || voiceOver || switchControl || voiceControl }

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.onScrollGeometryChange(for: Snapshot.self) { geo in
                Snapshot(offset: geo.contentOffset.y + geo.contentInsets.top,
                         contentHeight: geo.contentSize.height,
                         viewportHeight: geo.containerSize.height)
            } action: { _, snap in
                visibility.update(offset: snap.offset,
                                  contentHeight: snap.contentHeight,
                                  viewportHeight: snap.viewportHeight,
                                  locked: locked)
            }
        } else {
            content
        }
    }

    /// Deriving a small `Equatable` is what lets SwiftUI skip the action when
    /// nothing meaningful changed. Storing raw `ScrollGeometry` would fire on
    /// every frame.
    private struct Snapshot: Equatable {
        let offset: CGFloat
        let contentHeight: CGFloat
        let viewportHeight: CGFloat
    }
}
