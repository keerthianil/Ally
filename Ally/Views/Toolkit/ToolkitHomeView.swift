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
                                .floating(index, amplitude: 2)
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
            .tracksTabBar()
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
            Text("The maths is exact. The judgement stays yours.")
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
        /// The idling mark for this tool. Each animation restates what the tool
        /// does, which is the only reason to animate an icon at all.
        var art: LivingToolArt.Kind {
            switch self {
            case .contrast:    return .contrast
            case .cvd:         return .cvd
            case .readability: return .readability
            case .touchTarget: return .touchTarget
            case .wcag:        return .wcag
            }
        }
        var ink: Color {
            switch self {
            case .contrast:    return ColorTokens.visionInk
            case .cvd:         return ColorTokens.cognitiveInk
            case .readability: return ColorTokens.brandPrimaryInk
            case .touchTarget: return ColorTokens.motorInk
            case .wcag:        return ColorTokens.navigationInk
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

/// Same shape language as Learn's cards: a notch with the glyph living in it,
/// and art that idles. The difference is the fill, which is the elevated surface
/// rather than a category hue, so five tools in a column don't read as five
/// unrelated categories.
private struct ToolCard: View {
    let tool: ToolkitHomeView.ToolkitTool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(spacing: Spacing.lg) {
                LivingToolArt(kind: tool.art, tint: tool.color, ink: tool.ink, size: 52)
                    .padding(Spacing.sm)
                    .background(RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                        .fill(tool.color.opacity(0.34)))

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(tool.title)
                        .font(Typography.headline)
                        .foregroundStyle(ColorTokens.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(tool.blurb)
                        .font(Typography.subheadline)
                        .foregroundStyle(ColorTokens.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: Spacing.xl)
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(NotchedCard(notch: 40).fill(ColorTokens.surfaceElevated))
            .overlay(NotchedCard(notch: 40).stroke(ColorTokens.border, lineWidth: 1))

            NotchGlyph(systemName: "arrow.up.right", tint: tool.ink, size: 32)
                .offset(x: 2, y: -2)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(tool.title). \(tool.blurb)")
        .accessibilityHint("Opens the tool")
    }
}

#Preview { ToolkitHomeView() }
