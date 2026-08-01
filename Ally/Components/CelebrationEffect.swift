import SwiftUI

/// Four different reactions to a score, because one confetti burst for every
/// result is a lie the user can see through.
///
/// Confetti at 42 out of 100 reads as either sarcasm or as the app not having
/// looked at the number. But the opposite failure is worse: Ally's whole stance
/// is that accessibility guilt is the thing keeping people out, so a low score
/// cannot get *nothing*. Silence is a verdict too.
///
/// So the effects vary in **energy**, not in approval. Every band gets something
/// warm; what changes is how loud it is.
enum CelebrationBand: Equatable {
    /// 80 and up. Genuinely rare, and worth a party.
    case amazing
    /// 50 to 79. Real momentum, not a finish line.
    case good
    /// 30 to 49. A foundation exists. Steady, not celebratory.
    case foundation
    /// Under 30. You measured it, which is the hard part. Quiet and forward-looking.
    case beginning

    init(score: Int) {
        switch score {
        case 80...:   self = .amazing
        case 50..<80: self = .good
        case 30..<50: self = .foundation
        default:      self = .beginning
        }
    }

    var headline: String {
        switch self {
        case .amazing:    return "Amazing work!"
        case .good:       return "Real momentum"
        case .foundation: return "Foundation laid"
        case .beginning:  return "You measured it"
        }
    }

    var subtitle: String {
        switch self {
        case .amazing:
            return "This clears a bar most shipped apps miss. Share the report and keep it there."
        case .good:
            return "A solid, accessible base. A few focused fixes push this into the green."
        case .foundation:
            return "The bones are here. The report sorts what is left by how much it changes for people."
        case .beginning:
            return "Most teams never find out. You did, and now the list is finite and sorted."
        }
    }

    /// The colour the effect and the backdrop tint pull from.
    var accent: Color {
        switch self {
        case .amazing:    return ColorTokens.celebration
        case .good:       return ColorTokens.navigation
        case .foundation: return ColorTokens.brandSupport
        case .beginning:  return ColorTokens.cognitive
        }
    }

    /// Haptic weight matches visual weight.
    func playHaptic() {
        switch self {
        case .amazing:    Haptics.success()
        case .good:       Haptics.medium()
        case .foundation: Haptics.light()
        case .beginning:  Haptics.soft()
        }
    }
}

/// The band's visual reaction, layered over the celebration screen.
///
/// Under Reduce Motion each one resolves to a single composed still rather than
/// disappearing, so the moment still lands. That matters more here than anywhere
/// else in the app: this is the one screen whose entire job is a feeling.
struct CelebrationEffect: View {
    let band: CelebrationBand
    /// Bumped to replay.
    var trigger: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            switch band {
            case .amazing:    ConfettiView(trigger: trigger)
            case .good:       RisingMotes(accent: band.accent, reduceMotion: reduceMotion)
            case .foundation: RippleBloom(accent: band.accent, reduceMotion: reduceMotion)
            case .beginning:  DawnSweep(accent: band.accent, reduceMotion: reduceMotion)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Good: rising motes

/// Soft dots drifting upward and fading. Reads as lift rather than as a party.
/// Deliberately unhurried, because "momentum" is the message, not "finished".
private struct RisingMotes: View {
    let accent: Color
    let reduceMotion: Bool

    private struct Mote {
        let x: Double, size: Double, speed: Double, phase: Double, hue: Int
    }

    private static let motes: [Mote] = (0..<22).map { i in
        var g = SystemRandomNumberGenerator()
        return Mote(x: Double.random(in: 0.05...0.95, using: &g),
                    size: Double.random(in: 5...13, using: &g),
                    speed: Double.random(in: 0.16...0.34, using: &g),
                    phase: Double.random(in: 0...1, using: &g),
                    hue: i % 4)
    }

    private var palette: [Color] {
        [ColorTokens.navigation, ColorTokens.vision, ColorTokens.celebration, accent]
    }

    var body: some View {
        if reduceMotion {
            // Held at a pleasing mid-flight arrangement.
            Canvas { ctx, s in draw(ctx, s, t: 2.4, fade: false) }
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                Canvas { ctx, s in draw(ctx, s, t: Living.phase(timeline.date), fade: true) }
            }
        }
    }

    private func draw(_ ctx: GraphicsContext, _ s: CGSize, t: Double, fade: Bool) {
        for m in Self.motes {
            let p = ((t * m.speed) + m.phase).truncatingRemainder(dividingBy: 1)
            let y = s.height * (1.05 - 1.15 * p)
            // Gentle lateral sway so they do not read as a progress bar.
            let x = s.width * m.x + CGFloat(sin((t * 0.6 + m.phase * 6)) * 10)
            let alpha = fade ? sin(p * .pi) * 0.55 : 0.42
            let r = m.size
            ctx.fill(Path(ellipseIn: CGRect(x: x - r / 2, y: y - r / 2, width: r, height: r)),
                     with: .color(palette[m.hue].opacity(alpha)))
        }
    }
}

// MARK: - Foundation: ripple bloom

/// Two or three concentric rings expanding from the centre and dissolving.
/// Steady and structural, the visual equivalent of "something to build on".
private struct RippleBloom: View {
    let accent: Color
    let reduceMotion: Bool

    var body: some View {
        if reduceMotion {
            Canvas { ctx, s in draw(ctx, s, t: 1.1) }
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                Canvas { ctx, s in draw(ctx, s, t: Living.phase(timeline.date)) }
            }
        }
    }

    private func draw(_ ctx: GraphicsContext, _ s: CGSize, t: Double) {
        let centre = CGPoint(x: s.width / 2, y: s.height * 0.34)
        let maxR = max(s.width, s.height) * 0.62
        for i in 0..<3 {
            let p = Living.sweep(t, period: 4.2, offset: Double(i) * 0.33)
            let r = maxR * (0.18 + 0.82 * p)
            let alpha = (1 - p) * 0.30
            ctx.stroke(Path(ellipseIn: CGRect(x: centre.x - r, y: centre.y - r, width: r * 2, height: r * 2)),
                       with: .color(accent.opacity(alpha)),
                       lineWidth: 3 + 3 * (1 - p))
        }
    }
}

// MARK: - Beginning: dawn sweep

/// One slow warm band of light crossing the screen, low and wide. The quietest
/// of the four, and the only one that never repeats quickly: it should feel like
/// a horizon, not an animation demanding to be watched.
private struct DawnSweep: View {
    let accent: Color
    let reduceMotion: Bool

    var body: some View {
        if reduceMotion {
            Canvas { ctx, s in draw(ctx, s, t: 3.2) }
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                Canvas { ctx, s in draw(ctx, s, t: Living.phase(timeline.date)) }
            }
        }
    }

    private func draw(_ ctx: GraphicsContext, _ s: CGSize, t: Double) {
        let p = Living.pulse(t, period: 9.0)
        let y = s.height * (0.86 - 0.16 * p)
        let h = s.height * 0.34

        let band = Path(CGRect(x: -20, y: y - h / 2, width: s.width + 40, height: h))
        ctx.fill(band, with: .linearGradient(
            Gradient(colors: [accent.opacity(0), accent.opacity(0.20 + 0.10 * p), accent.opacity(0)]),
            startPoint: CGPoint(x: 0, y: y - h / 2),
            endPoint: CGPoint(x: 0, y: y + h / 2)))

        // A single small mark riding the band, so there is one thing to notice.
        let mx = s.width * (0.18 + 0.64 * Living.sweep(t, period: 11))
        let r = 7.0
        ctx.fill(Path(ellipseIn: CGRect(x: mx - r, y: y - r, width: r * 2, height: r * 2)),
                 with: .color(accent.opacity(0.55)))
    }
}

#Preview {
    VStack(spacing: 0) {
        ForEach([CelebrationBand.amazing, .good, .foundation, .beginning], id: \.self) { b in
            ZStack {
                ColorTokens.surface
                CelebrationEffect(band: b, trigger: 1)
                Text(b.headline).font(Typography.title3)
            }
            .frame(height: 180)
        }
    }
}

extension CelebrationBand: Hashable {}
