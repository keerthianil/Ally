import SwiftUI

/// Three reactions to a score, one per band, because one confetti burst for every
/// result is a lie the user can see through.
///
/// Confetti at 42 out of 100 reads as either sarcasm or as the app not having
/// looked at the number. But the opposite failure is worse: Ally's whole stance
/// is that accessibility guilt is the thing keeping people out, so a low score
/// cannot get *nothing*. Silence is a verdict too.
///
/// So the effects vary in **energy**, not in approval, and each one is built on a
/// different motion grammar so they can never be mistaken for one another:
///
/// | Band     | Grammar     | Direction  | Tempo    |
/// |----------|-------------|------------|----------|
/// | Strong   | Ovation     | radial out | fast     |
/// | Building | Ember rise  | vertical   | medium   |
/// | Starting | First light | horizontal | very slow|
///
/// The bands match the score colours exactly, so the green in the ring is the
/// green in the burst. Three bands rather than four: a traffic light is something
/// people already know how to read, and a fourth step made the difference between
/// two of them a matter of taste rather than of meaning.
enum CelebrationBand: Equatable, Hashable, CaseIterable {
    /// 80 and up. Genuinely rare, and worth a party.
    case strong
    /// 50 to 79. Real momentum, not a finish line.
    case building
    /// Under 50. You measured it, which is the hard part.
    case starting

    init(score: Int) {
        switch score {
        case 80...:   self = .strong
        case 50..<80: self = .building
        default:      self = .starting
        }
    }

    /// A representative score for the band, for previews and for asking the
    /// colour tokens a question they already know the answer to.
    var representativeScore: Int {
        switch self {
        case .strong:   return 90
        case .building: return 65
        case .starting: return 30
        }
    }

    var headline: String {
        switch self {
        case .strong:   return "Amazing work!"
        case .building: return "Real momentum"
        case .starting: return "You measured it"
        }
    }

    var subtitle: String {
        switch self {
        case .strong:
            return "This clears a bar most shipped apps miss. Share the report and keep it there."
        case .building:
            return "A solid, accessible base. A few focused fixes push this into the green."
        case .starting:
            return "Most teams never find out. You did, and now the list is finite and sorted."
        }
    }

    /// The band's own name, matching the ring and the project cards.
    var label: String { ColorTokens.scoreLabel(representativeScore) }

    /// The fill the effect and the backdrop tint pull from: green, orange, red.
    var accent: Color { ColorTokens.scoreColor(representativeScore) }

    /// The darkened version, for anything that has to be legible against the app
    /// surface rather than merely felt.
    var ink: Color { ColorTokens.scoreInk(representativeScore) }

    /// The effect's supporting hues. Never the band colour alone: a screen of one
    /// flat colour reads as a status light, and red on its own reads as an alarm.
    /// The low band in particular is deliberately warmed toward sunrise.
    ///
    /// Each palette mixes a fill with at least one *ink*. The fills are what make
    /// the effect feel soft; the inks are what make it visible. A first pass used
    /// only pastels and, on the cream surface at 60% opacity, the whole thing
    /// disappeared into the background it was drawn over.
    var palette: [Color] {
        switch self {
        case .strong:
            return [ColorTokens.scoreStrong, ColorTokens.scoreStrongInk,
                    ColorTokens.visionInk, ColorTokens.celebration]
        case .building:
            return [ColorTokens.scoreFair, ColorTokens.scoreFairInk, ColorTokens.brandSupportInk]
        case .starting:
            return [ColorTokens.scoreWeak, ColorTokens.brandSupportInk, ColorTokens.scoreWeakInk]
        }
    }

    /// Haptic weight matches visual weight, and each band has its own *rhythm*
    /// rather than its own intensity, so they are distinguishable with the screen
    /// off. One flourish, one beat, one breath.
    func playHaptic() {
        switch self {
        case .strong:
            Haptics.success()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) { Haptics.light() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) { Haptics.light() }
        case .building:
            Haptics.medium()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) { Haptics.soft() }
        case .starting:
            Haptics.soft()
        }
    }
}

/// The band's visual reaction, layered over the celebration screen.
///
/// Under Reduce Motion each one resolves to a single composed still rather than
/// disappearing, so the moment still lands. That matters more here than anywhere
/// else in the app: this is the one screen whose entire job is a feeling.
///
/// Nothing here cycles faster than three times a second. Ally teaches WCAG 2.3.1,
/// and a celebration screen is exactly where an app forgets it.
struct CelebrationEffect: View {
    let band: CelebrationBand
    /// Bumped to replay.
    var trigger: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            switch band {
            case .strong:   Ovation(band: band, trigger: trigger, reduceMotion: reduceMotion)
            case .building: EmberRise(band: band, reduceMotion: reduceMotion)
            case .starting: FirstLight(band: band, reduceMotion: reduceMotion)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Strong: ovation

/// Everything leaves the centre at once.
///
/// Deliberately *not* falling confetti. Confetti comes from above and happens to
/// you; this erupts from the score you just earned, which is the difference
/// between a party and a reward. Three layers, all radial: a halo that expands and
/// thins, ribbons that launch on an arc and tumble, and a scatter of sparks that
/// hang in the air afterwards.
private struct Ovation: View {
    let band: CelebrationBand
    let trigger: Int
    let reduceMotion: Bool

    @State private var start: Date?

    private struct Ribbon {
        let angle: Double      // launch direction, radians
        let speed: Double      // 0…1 of the max reach
        let spin: Double
        let length: Double
        let hue: Int
        let delay: Double
    }

    private static let ribbons: [Ribbon] = (0..<26).map { i in
        var g = SystemRandomNumberGenerator()
        // Biased upward and outward: a fan, not a uniform starburst, because a
        // perfect circle of ribbons reads as a loading spinner.
        let spread = Double.random(in: -1.0...1.0, using: &g)
        return Ribbon(angle: -.pi / 2 + spread * 1.5,
                      speed: Double.random(in: 0.55...1.0, using: &g),
                      spin: Double.random(in: -7...7, using: &g),
                      length: Double.random(in: 12...22, using: &g),
                      hue: i % 4,
                      delay: Double.random(in: 0...0.18, using: &g))
    }

    /// Sparks keep to the margins: anywhere in the upper third, or down the two
    /// side gutters. The headline and the subtitle live in the middle band, and a
    /// twinkling dot landing on a letter reads as a rendering fault rather than
    /// as atmosphere.
    private static let sparks: [(x: Double, y: Double, r: Double, phase: Double)] =
        (0..<18).map { i in
            var g = SystemRandomNumberGenerator()
            let inUpper = i % 5 != 0
            let x = inUpper
                ? Double.random(in: 0.06...0.94, using: &g)
                : (Bool.random(using: &g) ? Double.random(in: 0.03...0.13, using: &g)
                                          : Double.random(in: 0.87...0.97, using: &g))
            let y = inUpper
                ? Double.random(in: 0.06...0.30, using: &g)
                : Double.random(in: 0.30...0.80, using: &g)
            return (x, y,
                    Double.random(in: 2.0...4.5, using: &g),
                    Double.random(in: 0...1, using: &g))
        }

    private let duration: Double = 2.6

    var body: some View {
        if reduceMotion {
            // Held at the apex: halo mid-flight, ribbons fanned out, sparks lit.
            Canvas { ctx, s in
                drawBurst(ctx, s, p: 0.34)
                drawAmbient(ctx, s, t: 0.5, presence: 1)
            }
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
                Canvas { ctx, s in
                    let t = Living.phase(timeline.date)
                    let elapsed = start.map { timeline.date.timeIntervalSince($0) } ?? duration
                    if elapsed <= duration { drawBurst(ctx, s, p: elapsed / duration) }
                    // The ambient layer never stops. Without it the top band was
                    // the only one whose screen went completely empty after three
                    // seconds, which put the best score on the deadest screen.
                    drawAmbient(ctx, s, t: t,
                                presence: min(1, max(0, (elapsed / duration - 0.22) / 0.3)))
                }
            }
            .onChange(of: trigger) { _, _ in start = .now }
            .onAppear { if start == nil { start = .now } }
        }
    }

    /// The one-shot: everything leaves the centre.
    private func drawBurst(_ ctx: GraphicsContext, _ s: CGSize, p: Double) {
        let origin = CGPoint(x: s.width / 2, y: s.height * 0.34)
        let reach = max(s.width, s.height) * 0.72
        let palette = band.palette
        let fade = 1 - max(0, (p - 0.62) / 0.38)

        // Halo. Two rings leaving the score, thinning as they go.
        for i in 0..<2 {
            let hp = min(1, max(0, (p - Double(i) * 0.10) / 0.55))
            guard hp > 0 else { continue }
            let r = reach * (0.10 + 0.95 * easeOut(hp))
            ctx.stroke(Path(ellipseIn: CGRect(x: origin.x - r, y: origin.y - r,
                                              width: r * 2, height: r * 2)),
                       with: .color(band.accent.opacity(0.38 * (1 - hp) * fade)),
                       lineWidth: 8 * (1 - hp) + 1)
        }

        // Ribbons. Launched on an arc, pulled down by a soft gravity, tumbling.
        for rib in Self.ribbons {
            let rp = min(1, max(0, (p - rib.delay) / (1 - rib.delay)))
            guard rp > 0 else { continue }
            let travel = reach * rib.speed * easeOut(rp)
            let gravity = reach * 0.62 * rp * rp
            let x = origin.x + CGFloat(cos(rib.angle) * travel)
            let y = origin.y + CGFloat(sin(rib.angle) * travel) + CGFloat(gravity)

            var layer = ctx
            layer.translateBy(x: x, y: y)
            layer.rotate(by: .radians(rib.spin * rp * 2))
            layer.opacity = (1 - rp * 0.35) * fade
            let rect = CGRect(x: -rib.length / 2, y: -2.6, width: rib.length, height: 5.2)
            layer.fill(Path(roundedRect: rect, cornerRadius: 2.6),
                       with: .color(palette[rib.hue % palette.count]))
        }
    }

    /// The resting state: sparks hanging in the air, and one very slow ring that
    /// keeps leaving the score. Quiet enough to read over, alive enough that the
    /// screen still feels like the room after the applause.
    private func drawAmbient(_ ctx: GraphicsContext, _ s: CGSize, t: Double, presence: Double) {
        guard presence > 0 else { return }
        let origin = CGPoint(x: s.width / 2, y: s.height * 0.34)
        let reach = max(s.width, s.height) * 0.72

        let slow = Living.sweep(t, period: 7.5)
        let r = reach * (0.16 + 0.80 * slow)
        ctx.stroke(Path(ellipseIn: CGRect(x: origin.x - r, y: origin.y - r,
                                          width: r * 2, height: r * 2)),
                   with: .color(band.accent.opacity(0.16 * (1 - slow) * presence)),
                   lineWidth: 3)

        for sp in Self.sparks {
            // 0.85 Hz twinkle. Nowhere near the three-per-second flash limit.
            let twinkle = 0.5 + 0.5 * Living.pulse(t, period: 1.2, offset: sp.phase)
            let rr = sp.r * (0.5 + 0.5 * presence)
            ctx.fill(Path(ellipseIn: CGRect(x: s.width * sp.x - rr, y: s.height * sp.y - rr,
                                            width: rr * 2, height: rr * 2)),
                     with: .color(band.palette[1].opacity(0.55 * twinkle * presence)))
        }
    }

    private func easeOut(_ x: Double) -> Double { 1 - pow(1 - x, 3) }
}

// MARK: - Building: ember rise

/// Warmth going up.
///
/// Continuous rather than one-shot, because "momentum" is a state and not an
/// event. Everything moves in one direction at one unhurried speed: a warm glow
/// breathing at the bottom edge, and embers lifting through it, brightest where
/// they start and fading as they climb.
private struct EmberRise: View {
    let band: CelebrationBand
    let reduceMotion: Bool

    private struct Ember {
        let x: Double, size: Double, speed: Double, phase: Double, sway: Double, hue: Int
    }

    private static let embers: [Ember] = (0..<28).map { i in
        var g = SystemRandomNumberGenerator()
        return Ember(x: Double.random(in: 0.04...0.96, using: &g),
                     size: Double.random(in: 4...11, using: &g),
                     speed: Double.random(in: 0.10...0.22, using: &g),
                     phase: Double.random(in: 0...1, using: &g),
                     sway: Double.random(in: 6...18, using: &g),
                     hue: i % 3)
    }

    var body: some View {
        if reduceMotion {
            Canvas { ctx, s in draw(ctx, s, t: 3.1) }
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                Canvas { ctx, s in draw(ctx, s, t: Living.phase(timeline.date)) }
            }
        }
    }

    private func draw(_ ctx: GraphicsContext, _ s: CGSize, t: Double) {
        let palette = band.palette

        // The hearth: a warm wash rising off the bottom edge, breathing slowly.
        let breath = Living.pulse(t, period: 6.4)
        let glowHeight = s.height * (0.32 + 0.06 * breath)
        ctx.fill(Path(CGRect(x: 0, y: s.height - glowHeight, width: s.width, height: glowHeight)),
                 with: .linearGradient(
                    Gradient(colors: [band.accent.opacity(0), band.accent.opacity(0.26 + 0.08 * breath)]),
                    startPoint: CGPoint(x: 0, y: s.height - glowHeight),
                    endPoint: CGPoint(x: 0, y: s.height)))

        // The embers. Higher means dimmer and smaller, so the eye is pulled up.
        for e in Self.embers {
            let p = ((t * e.speed) + e.phase).truncatingRemainder(dividingBy: 1)
            let y = s.height * (1.04 - 1.12 * p)
            let x = s.width * e.x + CGFloat(sin(t * 0.5 + e.phase * 6.3) * e.sway)
            // Fade in fast, out slowly, so nothing pops into existence.
            let alpha = min(1, p / 0.12) * (1 - p) * 0.92
            let r = e.size * (1 - 0.35 * p)
            let colour = palette[e.hue % palette.count]

            // A soft halo under each ember gives the warmth without a blur filter.
            ctx.fill(Path(ellipseIn: CGRect(x: x - r * 1.9, y: y - r * 1.9,
                                            width: r * 3.8, height: r * 3.8)),
                     with: .color(colour.opacity(alpha * 0.22)))
            ctx.fill(Path(ellipseIn: CGRect(x: x - r / 2, y: y - r / 2, width: r, height: r)),
                     with: .color(colour.opacity(alpha)))
        }
    }
}

// MARK: - Starting: first light

/// A horizon, not an animation.
///
/// The quietest of the three and the only one that moves sideways. It is a
/// sunrise: warm strata stacked low, one band of light easing upward, and a
/// single mark travelling along it so there is exactly one thing to notice. It
/// takes about eleven seconds to do anything, which is the point. The message is
/// "this is the beginning of something", and a low score getting a fast, bright
/// effect would read as consolation.
private struct FirstLight: View {
    let band: CelebrationBand
    let reduceMotion: Bool

    var body: some View {
        if reduceMotion {
            Canvas { ctx, s in draw(ctx, s, t: 3.4) }
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { timeline in
                Canvas { ctx, s in draw(ctx, s, t: Living.phase(timeline.date)) }
            }
        }
    }

    private func draw(_ ctx: GraphicsContext, _ s: CGSize, t: Double) {
        let rise = Living.pulse(t, period: 11.0)
        let horizon = s.height * (0.84 - 0.04 * rise)
        let palette = band.palette

        // Strata: thin warm layers stacked around the horizon, thinning and
        // fading outward from it. They are what make the still frame a composed
        // picture rather than a stripe.
        //
        // They live in the bottom fifth on purpose. A first pass let them drift
        // to mid-screen and they landed straight across the headline, reading as
        // strikethroughs. Ambient motion is not allowed to cross running text.
        let offsets: [Double] = [-0.06, -0.03, 0.02, 0.06]
        for (i, off) in offsets.enumerated() {
            let drift = 0.008 * Living.pulse(t, period: 13, offset: Double(i) * 0.2)
            let y = horizon + s.height * CGFloat(off + drift)
            let h = max(1.5, 5.5 - abs(off) * 40)
            let inset = s.width * CGFloat(0.05 + Double(i) * 0.04)
            ctx.fill(Path(roundedRect: CGRect(x: inset, y: y - h / 2,
                                              width: s.width - inset * 2, height: h),
                          cornerRadius: h / 2),
                     with: .color(palette[(i + 1) % palette.count]
                        .opacity(0.22 - abs(off) * 1.6)))
        }

        // The band of light itself, soft-edged top and bottom.
        let h = s.height * 0.30
        ctx.fill(Path(CGRect(x: -20, y: horizon - h / 2, width: s.width + 40, height: h)),
                 with: .linearGradient(
                    Gradient(colors: [band.accent.opacity(0),
                                      band.accent.opacity(0.18 + 0.08 * rise),
                                      band.accent.opacity(0)]),
                    startPoint: CGPoint(x: 0, y: horizon - h / 2),
                    endPoint: CGPoint(x: 0, y: horizon + h / 2)))

        // One mark, travelling. Slow enough to look still if you glance at it.
        let travel = Living.sweep(t, period: 14)
        let mx = s.width * (0.12 + 0.76 * travel)
        let r = 6.5
        ctx.fill(Path(ellipseIn: CGRect(x: mx - r * 2.6, y: horizon - r * 2.6,
                                        width: r * 5.2, height: r * 5.2)),
                 with: .color(ColorTokens.celebration.opacity(0.16)))
        ctx.fill(Path(ellipseIn: CGRect(x: mx - r, y: horizon - r, width: r * 2, height: r * 2)),
                 with: .color(ColorTokens.celebration.opacity(0.85)))
    }
}

#Preview {
    VStack(spacing: 0) {
        ForEach(CelebrationBand.allCases, id: \.self) { b in
            ZStack {
                ColorTokens.surface
                CelebrationEffect(band: b, trigger: 1)
                VStack(spacing: 2) {
                    Text(b.headline).font(Typography.title3)
                    Text(b.label).font(Typography.eyebrow).foregroundStyle(b.ink)
                }
            }
            .frame(height: 220)
        }
    }
}
