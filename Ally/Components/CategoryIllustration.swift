import SwiftUI

/// Bespoke, custom-drawn illustration for each accessibility category — layered
/// SwiftUI shapes (not SF Symbols) with a slow, subtle life to them. This is the
/// signature visual language of the Learn tab. Every animation pauses under
/// Reduce Motion, and the whole thing is `accessibilityHidden` (decorative).
struct CategoryIllustration: View {
    let category: AccessibilityCategory
    var size: CGFloat = 96
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { timeline in
            let t = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                    .fill(category.color.opacity(0.16))
                RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                    .stroke(category.color.opacity(0.30), lineWidth: 1)

                switch category {
                case .vision:     VisionArt(t: t, color: category.color, ink: category.inkColor)
                case .motor:      MotorArt(t: t, color: category.color, ink: category.inkColor)
                case .cognitive:  CognitiveArt(t: t, color: category.color, ink: category.inkColor)
                case .navigation: NavigationArt(t: t, color: category.color, ink: category.inkColor)
                }
            }
            .frame(width: size, height: size)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Vision — a breathing eye that shifts its gaze

private struct VisionArt: View {
    let t: Double; let color: Color; let ink: Color
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            let breathe = 1.0 + 0.06 * sin(t * 1.4)
            let gazeX = 0.5 + 0.10 * cos(t * 0.9)
            let gazeY = 0.5 + 0.06 * sin(t * 1.1)
            ZStack {
                EyeShape()
                    .fill(Color.white.opacity(0.9))
                    .overlay(EyeShape().stroke(ink.opacity(0.55), lineWidth: s * 0.03))
                    .frame(width: s * 0.72, height: s * 0.46)
                // Iris
                Circle()
                    .fill(RadialGradient(colors: [color, ink],
                                         center: .center, startRadius: 0, endRadius: s * 0.16))
                    .frame(width: s * 0.28, height: s * 0.28)
                    .scaleEffect(breathe)
                    .position(x: s * gazeX, y: s * gazeY)
                // Pupil
                Circle().fill(Color(hex: 0x1A0E22))
                    .frame(width: s * 0.12, height: s * 0.12)
                    .position(x: s * gazeX, y: s * gazeY)
                // Catch-light
                Circle().fill(Color.white)
                    .frame(width: s * 0.05, height: s * 0.05)
                    .position(x: s * gazeX + s * 0.04, y: s * gazeY - s * 0.04)
            }
            .frame(width: s, height: s)
        }
    }
}

/// A symmetric almond built from two quadratic curves.
private struct EyeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY),
                       control: CGPoint(x: rect.midX, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.midY),
                       control: CGPoint(x: rect.midX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Motor — a touch target with an expanding tap ripple

private struct MotorArt: View {
    let t: Double; let color: Color; let ink: Color
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            let pulse = (sin(t * 1.6) + 1) / 2 // 0…1
            ZStack {
                // The "44pt zone" — dashed outer ring
                Circle()
                    .stroke(ink.opacity(0.45), style: StrokeStyle(lineWidth: s * 0.02, dash: [s * 0.05, s * 0.04]))
                    .frame(width: s * 0.66, height: s * 0.66)
                // Expanding ripple
                Circle()
                    .stroke(color.opacity(0.9 * (1 - pulse)), lineWidth: s * 0.03)
                    .frame(width: s * (0.28 + 0.4 * pulse), height: s * (0.28 + 0.4 * pulse))
                // Solid tap
                Circle()
                    .fill(RadialGradient(colors: [color, ink],
                                         center: .center, startRadius: 0, endRadius: s * 0.18))
                    .frame(width: s * 0.30, height: s * 0.30)
                    .shadow(color: ink.opacity(0.4), radius: s * 0.04, y: s * 0.02)
            }
            .frame(width: s, height: s)
        }
    }
}

// MARK: - Cognitive — a mind with orbiting, connected thoughts

private struct CognitiveArt: View {
    let t: Double; let color: Color; let ink: Color
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: s / 2, y: s / 2)
            let nodeCount = 4
            let nodes: [CGPoint] = (0..<nodeCount).map { i in
                let a = t * 0.5 + Double(i) / Double(nodeCount) * 2 * .pi
                let radius = s * 0.30
                return CGPoint(x: center.x + radius * cos(a), y: center.y + radius * sin(a))
            }
            ZStack {
                // Connections
                Path { p in
                    for n in nodes { p.move(to: center); p.addLine(to: n) }
                }
                .stroke(ink.opacity(0.35), lineWidth: s * 0.015)
                // Core
                RoundedRectangle(cornerRadius: s * 0.12, style: .continuous)
                    .fill(LinearGradient(colors: [color, ink], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: s * 0.26, height: s * 0.26)
                    .rotationEffect(.degrees(sin(t * 0.8) * 8))
                // Nodes
                ForEach(0..<nodeCount, id: \.self) { i in
                    Circle().fill(color)
                        .frame(width: s * 0.11, height: s * 0.11)
                        .position(nodes[i])
                }
            }
            .frame(width: s, height: s)
        }
    }
}

// MARK: - Navigation — a focus ring traveling a dotted path

private struct NavigationArt: View {
    let t: Double; let color: Color; let ink: Color
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            let progress = (sin(t * 1.0) + 1) / 2 // 0…1 back-and-forth
            ZStack {
                // Dotted route
                NavPath()
                    .stroke(ink.opacity(0.4), style: StrokeStyle(lineWidth: s * 0.02, lineCap: .round, dash: [s * 0.01, s * 0.06]))
                    .frame(width: s * 0.7, height: s * 0.7)
                // Waypoints
                ForEach(0..<3, id: \.self) { i in
                    Circle().fill(color.opacity(0.5))
                        .frame(width: s * 0.06, height: s * 0.06)
                        .position(NavPath.point(at: Double(i) / 2, in: CGSize(width: s * 0.7, height: s * 0.7)))
                        .offset(x: s * 0.15, y: s * 0.15)
                }
                // Traveling focus ring
                RoundedRectangle(cornerRadius: s * 0.05, style: .continuous)
                    .stroke(color, lineWidth: s * 0.035)
                    .frame(width: s * 0.2, height: s * 0.2)
                    .position(NavPath.point(at: progress, in: CGSize(width: s * 0.7, height: s * 0.7)))
                    .offset(x: s * 0.15, y: s * 0.15)
                    .shadow(color: color.opacity(0.5), radius: s * 0.04)
            }
            .frame(width: s, height: s)
        }
    }
}

/// An S-curve route used by the Navigation illustration.
private struct NavPath: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.midY),
                       control: CGPoint(x: rect.minX, y: rect.midY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY),
                       control: CGPoint(x: rect.maxX, y: rect.midY))
        return p
    }

    /// Approximate point along the S-curve for a normalized `s` in 0…1.
    static func point(at s: Double, in size: CGSize) -> CGPoint {
        let clamped = max(0, min(1, s))
        if clamped < 0.5 {
            let u = clamped / 0.5
            return quad(CGPoint(x: 0, y: size.height),
                        CGPoint(x: 0, y: size.height / 2),
                        CGPoint(x: size.width / 2, y: size.height / 2), u)
        } else {
            let u = (clamped - 0.5) / 0.5
            return quad(CGPoint(x: size.width / 2, y: size.height / 2),
                        CGPoint(x: size.width, y: size.height / 2),
                        CGPoint(x: size.width, y: 0), u)
        }
    }

    private static func quad(_ a: CGPoint, _ c: CGPoint, _ b: CGPoint, _ u: Double) -> CGPoint {
        let mu = 1 - u
        let x = mu * mu * a.x + 2 * mu * u * c.x + u * u * b.x
        let y = mu * mu * a.y + 2 * mu * u * c.y + u * u * b.y
        return CGPoint(x: x, y: y)
    }
}

#Preview {
    HStack(spacing: 16) {
        ForEach(AccessibilityCategory.allCases) { CategoryIllustration(category: $0, size: 80) }
    }
    .padding()
}
