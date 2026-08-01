import SwiftUI

/// The app's signature animation: a hand-drawn ring split into four category
/// segments. Each segment's fill length reflects that category's score; the whole
/// thing sweep-fills on appear with a soft glow, and the overall score counts up
/// in the center. Reduce Motion snaps to the final state (no sweep, no count).
struct ScoreRing: View {
    let result: ScoreEngine.Result
    var size: CGFloat = 240
    var lineWidth: CGFloat = 20

    @State private var progress: CGFloat = 0
    @State private var displayScore: Int = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let gapDegrees: Double = 8

    var body: some View {
        ZStack {
            Canvas { context, canvasSize in
                let rect = CGRect(origin: .zero, size: canvasSize)
                    .insetBy(dx: lineWidth, dy: lineWidth)
                let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
                let radius = min(rect.width, rect.height) / 2

                for (i, cat) in AccessibilityCategory.allCases.enumerated() {
                    let quadrantStart = Double(i) * 90 - 90 // start at top
                    let s = quadrantStart + gapDegrees / 2
                    let e = quadrantStart + 90 - gapDegrees / 2
                    let cscore = Double(result.score(for: cat)) / 100.0
                    let filledEnd = s + (e - s) * cscore * Double(progress)

                    // Track — a decorative tint of the category hue.
                    context.stroke(
                        arc(center: center, radius: radius, from: s, to: e),
                        with: .color(cat.color.opacity(0.15)),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

                    // Glow (blurred copy under the fill)
                    if cscore > 0 {
                        var glow = context
                        glow.addFilter(.blur(radius: 8))
                        glow.stroke(
                            arc(center: center, radius: radius, from: s, to: filledEnd),
                            with: .color(cat.inkColor.opacity(0.6)),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                        // Fill — the ink, not the fill hue. The arc *is* the
                        // information, so it has to clear 3:1 against its own track
                        // (WCAG 1.4.11); cyan-on-cyan-tint only manages 1.75:1.
                        context.stroke(
                            arc(center: center, radius: radius, from: s, to: filledEnd),
                            with: .color(cat.inkColor),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    }
                }
            }
            .frame(width: size, height: size)

            center
        }
        .frame(width: size, height: size)
        .onAppear(perform: animateIn)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Accessibility score \(result.overall) out of 100")
    }

    private var center: some View {
        VStack(spacing: 2) {
            Text("\(displayScore)")
                .font(Typography.scoreNumeral)
                .foregroundStyle(ColorTokens.textPrimary)
                .contentTransition(.numericText(value: Double(displayScore)))
            Text("out of 100")
                .font(Typography.caption)
                .foregroundStyle(ColorTokens.textSecondary)
            Text(band.label.uppercased())
                .font(Typography.eyebrow)
                .foregroundStyle(ColorTokens.scoreInk(result.overall))
                .padding(.top, 2)
        }
    }

    private var band: (label: String, _c: Int) {
        switch result.overall {
        case 80...:   return ("Strong", 0)
        case 60..<80: return ("Getting there", 0)
        default:      return ("Needs work", 0)
        }
    }

    private func animateIn() {
        guard !reduceMotion else {
            progress = 1; displayScore = result.overall; return
        }
        withAnimation(AnimationTokens.ringFill) { progress = 1 }
        withAnimation(.easeOut(duration: 1.1)) { displayScore = result.overall }
    }

    /// Build a stroked arc path between two angles (degrees).
    private func arc(center: CGPoint, radius: CGFloat, from: Double, to: Double) -> Path {
        var p = Path()
        p.addArc(center: center, radius: radius,
                 startAngle: .degrees(from), endAngle: .degrees(to), clockwise: false)
        return p
    }
}
