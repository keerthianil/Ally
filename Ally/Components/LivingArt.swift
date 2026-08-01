import SwiftUI

/// The app's motion vocabulary, in one place.
///
/// Ally teaches WCAG 2.3.3, so every one of these has to have a still version
/// that is composed rather than merely frozen. The rule used throughout: motion
/// carries *personality*, never information. Nothing here is the only way to
/// learn anything, so switching it all off costs the user nothing.
enum Living {

    /// A shared clock. `TimelineView(.animation)` per-view would give every
    /// sticker its own phase and the screen would look like it was buffering;
    /// driving everything from one absolute time and offsetting by index keeps
    /// the whole page breathing together.
    static func phase(_ date: Date, speed: Double = 1) -> Double {
        date.timeIntervalSinceReferenceDate * speed
    }

    /// Eased 0…1…0 loop.
    static func pulse(_ t: Double, period: Double = 2.6, offset: Double = 0) -> Double {
        let x = ((t / period) + offset).truncatingRemainder(dividingBy: 1)
        return 0.5 - 0.5 * cos(x * 2 * .pi)
    }

    /// One-way 0…1 ramp, for things that travel rather than breathe.
    static func sweep(_ t: Double, period: Double = 4, offset: Double = 0) -> Double {
        (((t / period) + offset).truncatingRemainder(dividingBy: 1) + 1).truncatingRemainder(dividingBy: 1)
    }
}

// MARK: - Floating

/// A very small vertical drift, phase-offset per item so a grid of cards moves
/// like a raft rather than a single block. Amplitude is deliberately under 4pt:
/// enough to notice at rest, not enough to fight a reading eye.
struct FloatModifier: ViewModifier {
    var index: Int
    var amplitude: CGFloat = 3
    var period: Double = 5.5

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                let t = Living.phase(timeline.date)
                content.offset(y: amplitude * sin((t / period + Double(index) * 0.17) * 2 * .pi))
            }
        }
    }
}

extension View {
    /// Idle drift. Pass the item's position so neighbours move out of step.
    func floating(_ index: Int, amplitude: CGFloat = 3) -> some View {
        modifier(FloatModifier(index: index, amplitude: amplitude))
    }
}

// MARK: - Living category art

/// Flat cut-out art, one per lens, drawn from primitives and idling.
///
/// Each lens moves in a way that restates what it's about, which is the only
/// justification for animating an icon at all: the eye tracks and blinks, the
/// tap target ripples outward, the thought nodes orbit, the route marker
/// travels. Under Reduce Motion each settles into its most legible frame, not
/// frame zero.
struct LivingCategoryArt: View {
    let category: AccessibilityCategory
    var size: CGFloat = 72
    /// Set when the art sits on a card painted in its own category hue. Without
    /// it the pastel body is invisible against the pastel card and only the ink
    /// marks survive.
    var onCategoryFill: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if reduceMotion {
                canvas(t: restingTime)
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                    canvas(t: Living.phase(timeline.date))
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    /// The frame each lens looks best held at: eye open and centred, ripple
    /// mid-flight, nodes evenly spread, marker part-way along the route.
    private var restingTime: Double {
        switch category {
        case .vision:     return 0.65
        case .motor:      return 1.3
        case .cognitive:  return 0
        case .navigation: return 2.2
        }
    }

    private func canvas(t: Double) -> some View {
        Canvas { ctx, s in
            let w = s.width, h = s.height
            let body = GraphicsContext.Shading.color(onCategoryFill ? Color.white.opacity(0.94) : category.color)
            let ink = GraphicsContext.Shading.color(category.inkColor)
            let spark = onCategoryFill ? category.color : Color.white.opacity(0.92)

            switch category {
            case .vision:
                // Blink: a short lid close on a long cycle, so it reads as alive
                // rather than as a strobe. Nothing under 0.3s.
                let blinkCycle = Living.sweep(t, period: 5.2)
                let lid = blinkCycle > 0.93 ? (1 - abs(blinkCycle - 0.965) / 0.035) : 0
                let open = 1 - lid * 0.92

                var eye = Path()
                let lift = h * 0.44 * open
                eye.move(to: CGPoint(x: w * 0.05, y: h * 0.5))
                eye.addQuadCurve(to: CGPoint(x: w * 0.95, y: h * 0.5),
                                 control: CGPoint(x: w * 0.5, y: h * 0.5 - lift))
                eye.addQuadCurve(to: CGPoint(x: w * 0.05, y: h * 0.5),
                                 control: CGPoint(x: w * 0.5, y: h * 0.5 + lift))
                ctx.fill(eye, with: body)

                if open > 0.35 {
                    // Look around: slow lateral drift with a pause at each end.
                    let gaze = sin(t / 3.1 * 2 * .pi)
                    let cx = w * (0.5 + 0.13 * gaze)
                    let ir = w * 0.13
                    ctx.fill(Path(ellipseIn: CGRect(x: cx - ir, y: h * 0.5 - ir * 1.35,
                                                    width: ir * 2, height: ir * 2.7)), with: ink)
                    ctx.fill(Path(ellipseIn: CGRect(x: cx - ir * 0.30, y: h * 0.5 - ir * 0.95,
                                                    width: ir * 0.6, height: ir * 0.7)),
                             with: .color(spark))
                }

            case .motor:
                // A ripple leaves the centre and fades, on repeat: the target is
                // being pressed, not just aimed at.
                ctx.stroke(Path(ellipseIn: CGRect(x: w * 0.10, y: h * 0.10, width: w * 0.80, height: h * 0.80)),
                           with: body, lineWidth: w * 0.11)
                ctx.stroke(Path(ellipseIn: CGRect(x: w * 0.27, y: h * 0.27, width: w * 0.46, height: h * 0.46)),
                           with: ink, lineWidth: w * 0.09)

                let press = Living.pulse(t, period: 2.4)
                let dotR = w * (0.09 + 0.022 * press)
                ctx.fill(Path(ellipseIn: CGRect(x: w * 0.5 - dotR, y: h * 0.5 - dotR,
                                                width: dotR * 2, height: dotR * 2)), with: ink)

                let ripple = Living.sweep(t, period: 2.4)
                if ripple > 0.05 {
                    let rr = w * (0.24 + 0.30 * ripple)
                    var arc = Path()
                    arc.addEllipse(in: CGRect(x: w * 0.5 - rr, y: h * 0.5 - rr, width: rr * 2, height: rr * 2))
                    ctx.stroke(arc, with: .color((onCategoryFill ? Color.white : category.inkColor)
                        .opacity(0.55 * (1 - ripple))), lineWidth: w * 0.06)
                }

            case .cognitive:
                // Nodes orbit a core at different radii, so it reads as thinking
                // rather than loading.
                let coreR = w * (0.19 + 0.012 * Living.pulse(t, period: 3.2))
                ctx.fill(Path(ellipseIn: CGRect(x: w * 0.5 - coreR, y: h * 0.5 - coreR,
                                                width: coreR * 2, height: coreR * 2)), with: body)
                let orbits: [(r: Double, speed: Double, d: Double, phase: Double)] = [
                    (0.36, 0.34, 0.15, 0.0), (0.30, -0.27, 0.12, 0.45), (0.40, 0.20, 0.10, 0.72)
                ]
                for o in orbits {
                    let a = (t * o.speed + o.phase) * 2 * .pi
                    let cx = w * 0.5 + w * o.r * cos(a)
                    let cy = h * 0.5 + h * o.r * sin(a)
                    let d = w * o.d
                    ctx.fill(Path(ellipseIn: CGRect(x: cx - d / 2, y: cy - d / 2, width: d, height: d)), with: ink)
                }

            case .navigation:
                // A marker travels the route and loops. The path stays drawn, so
                // the still frame is a complete picture.
                var route = Path()
                let a = CGPoint(x: w * 0.12, y: h * 0.86)
                let c1 = CGPoint(x: w * 0.52, y: h * 0.94)
                let c2 = CGPoint(x: w * 0.30, y: h * 0.22)
                let b = CGPoint(x: w * 0.84, y: h * 0.20)
                route.move(to: a)
                route.addCurve(to: b, control1: c1, control2: c2)
                ctx.stroke(route, with: body, style: StrokeStyle(lineWidth: w * 0.13, lineCap: .round))

                let p = Living.sweep(t, period: 4.4)
                let pt = cubic(a, c1, c2, b, p)
                let mr = w * 0.14
                ctx.fill(Path(ellipseIn: CGRect(x: pt.x - mr, y: pt.y - mr, width: mr * 2, height: mr * 2)), with: ink)
                ctx.fill(Path(ellipseIn: CGRect(x: pt.x - mr * 0.34, y: pt.y - mr * 0.34,
                                                width: mr * 0.68, height: mr * 0.68)), with: .color(spark))
            }
        }
    }

    private func cubic(_ p0: CGPoint, _ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint, _ t: Double) -> CGPoint {
        let u = 1 - t
        let x = u * u * u * p0.x + 3 * u * u * t * p1.x + 3 * u * t * t * p2.x + t * t * t * p3.x
        let y = u * u * u * p0.y + 3 * u * u * t * p1.y + 3 * u * t * t * p2.y + t * t * t * p3.y
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Toolkit art

/// One idling mark per tool, same two-tone recipe as the category art so the
/// Toolkit tab reads as part of the same set rather than a row of SF Symbols.
struct LivingToolArt: View {
    enum Kind { case contrast, cvd, readability, touchTarget, wcag }

    let kind: Kind
    var tint: Color
    var ink: Color
    var size: CGFloat = 56

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if reduceMotion {
                canvas(t: 0.9)
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                    canvas(t: Living.phase(timeline.date))
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private func canvas(t: Double) -> some View {
        Canvas { ctx, s in
            let w = s.width, h = s.height
            let bodyS = GraphicsContext.Shading.color(tint)
            let inkS = GraphicsContext.Shading.color(ink)

            switch kind {
            case .contrast:
                // A disc whose dark half slides across, which is the tool's job.
                ctx.fill(Path(ellipseIn: CGRect(x: w * 0.08, y: h * 0.08, width: w * 0.84, height: h * 0.84)), with: bodyS)
                let split = 0.30 + 0.40 * Living.pulse(t, period: 3.4)
                var half = Path()
                half.addRect(CGRect(x: w * 0.08, y: h * 0.08, width: w * 0.84 * split, height: h * 0.84))
                ctx.clip(to: Path(ellipseIn: CGRect(x: w * 0.08, y: h * 0.08, width: w * 0.84, height: h * 0.84)))
                ctx.fill(half, with: inkS)

            case .cvd:
                // Three swatches trading places, the simulator in miniature.
                for i in 0..<3 {
                    let lift = h * 0.06 * sin((t / 2.8 + Double(i) * 0.3) * 2 * .pi)
                    let x = w * (0.12 + Double(i) * 0.28)
                    let rect = CGRect(x: x, y: h * 0.30 + lift, width: w * 0.22, height: h * 0.40)
                    ctx.fill(Path(roundedRect: rect, cornerRadius: w * 0.06),
                             with: i == 1 ? inkS : bodyS)
                }

            case .readability:
                // Text lines shortening, which is what a rewrite does.
                for i in 0..<4 {
                    let base = [0.78, 0.62, 0.70, 0.44][i]
                    let squeeze = 1 - 0.22 * Living.pulse(t, period: 3.6, offset: Double(i) * 0.12)
                    let rect = CGRect(x: w * 0.12, y: h * (0.22 + Double(i) * 0.16),
                                      width: w * base * squeeze, height: h * 0.085)
                    ctx.fill(Path(roundedRect: rect, cornerRadius: h * 0.045),
                             with: i == 0 ? inkS : bodyS)
                }

            case .touchTarget:
                // A square growing into the 44pt minimum and settling.
                let grow = 0.62 + 0.38 * Living.pulse(t, period: 3.0)
                let side = w * 0.72 * grow
                ctx.stroke(Path(roundedRect: CGRect(x: w * 0.14, y: h * 0.14, width: w * 0.72, height: h * 0.72),
                                cornerRadius: w * 0.12), with: bodyS, lineWidth: w * 0.06)
                ctx.fill(Path(roundedRect: CGRect(x: w * 0.5 - side / 2, y: h * 0.5 - side / 2,
                                                  width: side, height: side), cornerRadius: w * 0.10), with: inkS)

            case .wcag:
                // A stack of criteria, one highlighted in turn.
                let active = Int(Living.sweep(t, period: 4.2) * 4) % 4
                for i in 0..<4 {
                    let rect = CGRect(x: w * 0.14, y: h * (0.16 + Double(i) * 0.19),
                                      width: w * 0.72, height: h * 0.13)
                    ctx.fill(Path(roundedRect: rect, cornerRadius: h * 0.05),
                             with: i == active ? inkS : bodyS)
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 28) {
        HStack(spacing: 18) {
            ForEach(AccessibilityCategory.allCases) { LivingCategoryArt(category: $0, size: 64) }
        }
        HStack(spacing: 18) {
            ForEach([LivingToolArt.Kind.contrast, .cvd, .readability, .touchTarget, .wcag], id: \.self) { k in
                LivingToolArt(kind: k, tint: ColorTokens.cognitive, ink: ColorTokens.cognitiveInk)
            }
        }
    }
    .padding(40)
    .background(ColorTokens.surface)
}

extension LivingToolArt.Kind: Hashable {}
