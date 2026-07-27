import SwiftUI

/// Toolkit tab — five practical tools, each a full-screen mini-app. Bold tool
/// cards with a colored icon tile and one line on what it does.
struct ToolkitHomeView: View {
    @State private var appeared = false
    @State private var path: [ToolkitTool] = []
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    header
                    VStack(spacing: Spacing.lg) {
                        ForEach(Array(ToolkitTool.allCases.enumerated()), id: \.element) { index, tool in
                            NavigationLink(value: tool) { ToolCard(tool: tool) }
                                .buttonStyle(.pressableCard)
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 24)
                                .animation(reduceMotion ? .easeInOut(duration: 0.2)
                                           : AnimationTokens.spring.delay(Double(index) * 0.06), value: appeared)
                        }
                    }
                }
                .padding(Spacing.xl)
                .padding(.top, Spacing.xxl)
                .padding(.bottom, 110)
            }
            .background(AllyBackground())
            .scrollIndicators(.hidden)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: ToolkitTool.self) { tool in
                switch tool {
                case .contrast:    ContrastCheckerView()
                case .cvd:         CVDSimulatorView()
                case .readability: ReadabilityView()
                case .touchTarget: TouchTargetCalcView()
                case .wcag:        WCAGReferenceView()
                }
            }
            .onAppear {
                withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : AnimationTokens.spring) { appeared = true }
                autoOpenIfNeeded()
            }
        }
    }

    /// Screenshot helper: `-openTool <rawValue>` jumps straight into a tool.
    private func autoOpenIfNeeded() {
        let args = CommandLine.arguments
        guard let i = args.firstIndex(of: "-openTool"), i + 1 < args.count,
              let tool = ToolkitTool(rawValue: args[i + 1]), path.isEmpty else { return }
        path = [tool]
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("PRACTICAL TOOLS")
                .font(Typography.eyebrow).foregroundStyle(ColorTokens.brandPrimaryInk)
            Text("Toolkit")
                .font(Typography.display).foregroundStyle(ColorTokens.textPrimary)
            Text("Five things you'll reach for while you work.")
                .font(Typography.callout).foregroundStyle(ColorTokens.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    enum ToolkitTool: String, CaseIterable, Identifiable {
        case contrast, cvd, readability, touchTarget, wcag
        var id: String { rawValue }
        var title: String {
            switch self {
            case .contrast:    return "Contrast Checker"
            case .cvd:         return "Color Blindness Simulator"
            case .readability: return "Text Readability"
            case .touchTarget: return "Touch Target Calculator"
            case .wcag:        return "WCAG Quick Reference"
            }
        }
        var blurb: String {
            switch self {
            case .contrast:    return "Two colors → WCAG ratio + a fix"
            case .cvd:         return "See your UI through 8 CVD types"
            case .readability: return "Grade level + jargon flags"
            case .touchTarget: return "Check 44 / 48 / 24 minimums"
            case .wcag:        return "Searchable spec, in plain words"
            }
        }
        var symbol: String {
            switch self {
            case .contrast:    return "circle.lefthalf.filled"
            case .cvd:         return "eye.trianglebadge.exclamationmark.fill"
            case .readability: return "text.magnifyingglass"
            case .touchTarget: return "hand.point.up.left.fill"
            case .wcag:        return "list.bullet.rectangle.portrait.fill"
            }
        }
        var color: Color {
            switch self {
            case .contrast:    return ColorTokens.vision
            case .cvd:         return ColorTokens.cognitive
            case .readability: return ColorTokens.brandPrimary
            case .touchTarget: return ColorTokens.motor
            case .wcag:        return ColorTokens.navigation
            }
        }
    }
}

/// Matches the Learn tab's magazine cards: a category-colored accent strip on
/// top, then the icon + title + blurb — same corner radius, shadow, and spacing
/// tokens so the two tabs read as one system.
private struct ToolCard: View {
    let tool: ToolkitHomeView.ToolkitTool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(tool.color)
                .frame(height: 6)

            HStack(spacing: Spacing.lg) {
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                        .fill(tool.color.opacity(0.18))
                    Image(systemName: tool.symbol)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(tool.color)
                }
                .frame(width: 60, height: 60)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(tool.title).font(Typography.headline).foregroundStyle(ColorTokens.textPrimary)
                    Text(tool.blurb).font(Typography.subheadline).foregroundStyle(ColorTokens.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.system(size: 14, weight: .bold))
                    .foregroundStyle(ColorTokens.textTertiary)
            }
            .padding(Spacing.lg)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorTokens.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous).stroke(ColorTokens.border, lineWidth: 0.5))
        .shadow(color: tool.color.opacity(0.12), radius: 10, y: 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(tool.title). \(tool.blurb)")
    }
}

#Preview { ToolkitHomeView() }
