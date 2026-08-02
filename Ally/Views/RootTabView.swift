import SwiftUI

/// App shell: the three tabs plus a custom, animated floating tab bar.
/// We hand-roll the bar (instead of `TabView`'s) so the selection indicator can
/// spring between items and match Ally's playful personality — while staying
/// fully accessible (each item is a `button` with a `.isSelected` trait).
struct RootTabView: View {
    @State private var selection: Tab = {
        let args = CommandLine.arguments
        if args.contains("-openResult") || args.contains("-openCelebration") || args.contains("-tabCheck") { return .check }
        if args.contains("-openTool") || args.contains("-tabToolkit") { return .toolkit }
        return .learn
    }()
    @Namespace private var indicator
    @State private var visibility = TabBarVisibility()

    var body: some View {
        ZStack(alignment: .bottom) {
            ColorTokens.surface.ignoresSafeArea()

            Group {
                switch selection {
                case .learn:   LearnHomeView()
                case .check:   CheckHomeView()
                case .toolkit: ToolkitHomeView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Gone entirely on a pushed screen, the way UIKit has hidden the bar
            // on push since the beginning. Every detail screen has its own back
            // button, so nothing becomes unreachable, and the bar stops covering
            // the bottom of screens whose scroll it was never tracking.
            if !visibility.isHidden {
                AllyTabBar(selection: $selection, indicator: indicator, visibility: visibility)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .environment(\.tabBarVisibility, visibility)
        // Each tab tracks its own scroll, so switching tabs has to start clean.
        .onChange(of: selection) { _, _ in visibility.reset() }
    }

    enum Tab: String, CaseIterable, Identifiable {
        case learn, check, toolkit
        var id: String { rawValue }

        var title: String {
            switch self {
            case .learn:   return "Learn"
            case .check:   return "Check"
            case .toolkit: return "Toolkit"
            }
        }
        var symbol: String {
            switch self {
            case .learn:   return "sparkles"
            case .check:   return "checkmark.seal.fill"
            case .toolkit: return "wrench.and.screwdriver.fill"
            }
        }
    }
}

private struct AllyTabBar: View {
    @Binding var selection: RootTabView.Tab
    var indicator: Namespace.ID
    var visibility: TabBarVisibility
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Collapsed shows only the current tab, still tappable, and tapping it
    /// brings the others back. It never disappears: a control that vanishes
    /// mid-reach is a motor failure, and one that is off screen cannot be
    /// reached by Switch Control or named by Voice Control at all.
    private var collapsed: Bool { visibility.isCollapsed }

    var body: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(RootTabView.Tab.allCases) { tab in
                if !collapsed || tab == selection {
                    item(for: tab)
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
        }
        .padding(Spacing.xs)
        .background(
            Capsule(style: .continuous)
                .fill(ColorTokens.surfaceElevated)
                .shadow(color: .black.opacity(0.12), radius: 18, y: 6)
        )
        .overlay(
            Capsule(style: .continuous).stroke(ColorTokens.border, lineWidth: 0.5)
        )
        .padding(.horizontal, Spacing.xxl)
        .padding(.bottom, Spacing.sm)
        // Tapping the collapsed pill expands it, so reaching another tab never
        // requires scrolling back up first.
        .onTapGesture {
            guard collapsed else { return }
            Haptics.light()
            visibility.expand()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(collapsed ? "Tabs, collapsed. Currently \(selection.title)." : "Tabs")
        .accessibilityHint(collapsed ? "Activate to show all tabs" : "")
    }

    private func item(for tab: RootTabView.Tab) -> some View {
        let isSelected = selection == tab
        return Button {
            selection = tab
            Haptics.selection()
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: tab.symbol)
                    .font(.system(size: 17, weight: .semibold))
                if isSelected {
                    Text(tab.title)
                        .font(Typography.headline)
                        .lineLimit(1)
                        .fixedSize()
                        .transition(.opacity.combined(with: .scale(scale: 0.85)))
                }
            }
            .foregroundStyle(isSelected ? ColorTokens.onBrand : ColorTokens.textSecondary)
            .padding(.vertical, Spacing.md)
            .padding(.horizontal, isSelected ? Spacing.lg : Spacing.md)
            .frame(minWidth: 52, minHeight: 44)
            .background {
                if isSelected {
                    Capsule(style: .continuous)
                        .fill(ColorTokens.brandPrimary)
                        .matchedGeometryEffect(id: "selectedTab", in: indicator)
                }
            }
            // Make the full padded frame — not just the glyph — the tap/AX target,
            // so every tab clears the 44pt minimum (verified by the a11y audit).
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .allyAnimation(AnimationTokens.spring, value: selection)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: [Project.self, Checkpoint.self, CheckpointHistory.self],
                        inMemory: true)
}
