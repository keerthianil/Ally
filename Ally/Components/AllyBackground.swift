import SwiftUI

/// The signature backdrop that runs behind **every tab**, giving the whole app a
/// single cohesive personality: concentric arcs sweeping off the top-right, a slow
/// spiral anchored bottom-left, and soft color blooms. Deliberately low-contrast so
/// it never fights the content (or its own accessibility rules).
///
/// Pass an `accent` to tint the whole motif to a category's color (used on Learn
/// detail screens); omit it for the full Grape-Fizz spectrum used on tab roots.
struct AllyBackground: View {
    var accent: Color? = nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var scheme

    private var palette: [Color] {
        if let accent { return [accent, accent.opacity(0.6), accent] }
        return [ColorTokens.brandPrimary, ColorTokens.vision,
                ColorTokens.cognitive, ColorTokens.navigation, ColorTokens.brandSupport]
    }

    /// Shapes read a touch stronger in dark mode where the surface is deep.
    private var strength: Double { scheme == .dark ? 1.5 : 1.0 }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: reduceMotion)) { timeline in
            let t = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                ColorTokens.surface
                GeometryReader { geo in
                    decor(w: geo.size.width, h: geo.size.height, t: t)
                }
            }
            .ignoresSafeArea()
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func decor(w: CGFloat, h: CGFloat, t: Double) -> some View {
        ZStack {
            // Soft color blooms
            bloom(palette[0])
                .frame(width: w * 1.1, height: w * 1.1)
                .position(x: w * 0.85, y: h * 0.12)
            bloom(palette.count > 1 ? palette[1] : ColorTokens.vision)
                .frame(width: w, height: w)
                .position(x: w * 0.10, y: h * 0.90)

            // Concentric arcs sweeping off the top-right corner
            ForEach(0..<5, id: \.self) { i in
                arc(diameter: w * (0.5 + CGFloat(i) * 0.34), color: palette[i % palette.count])
                    .position(x: w * 0.98, y: h * 0.02)
            }

            // Slow spiral anchored bottom-left
            SpiralShape(turns: 3.2)
                .stroke((accent ?? ColorTokens.brandPrimary).opacity(0.12 * strength),
                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                .frame(width: w * 0.75, height: w * 0.75)
                .rotationEffect(.radians(t * 0.05))
                .position(x: w * 0.08, y: h * 0.82)
        }
    }

    private func arc(diameter: CGFloat, color: Color) -> some View {
        Circle()
            .stroke(color.opacity(0.16 * strength), lineWidth: 2.5)
            .frame(width: diameter, height: diameter)
    }

    private func bloom(_ color: Color) -> some View {
        Circle()
            .fill(RadialGradient(
                colors: [color.opacity(0.22 * strength), color.opacity(0.0)],
                center: .center, startRadius: 0, endRadius: 220))
            .blur(radius: 30)
    }
}

/// An Archimedean spiral used as a decorative flourish.
private struct SpiralShape: Shape {
    var turns: Double = 3

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let maxR = min(rect.width, rect.height) / 2
        let total = turns * 2 * .pi
        var theta = 0.0
        var first = true
        while theta <= total {
            let r = maxR * (theta / total)
            let pt = CGPoint(x: center.x + r * cos(theta), y: center.y + r * sin(theta))
            if first { p.move(to: pt); first = false } else { p.addLine(to: pt) }
            theta += 0.15
        }
        return p
    }
}
