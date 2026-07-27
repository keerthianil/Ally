import SwiftUI

/// The moment of payoff. After the last checkpoint, the score sweeps in on the
/// signature ring with a band-specific, encouraging headline (and confetti for
/// high scores) — *then* the user taps through to the dense report. Celebrate
/// first, analyze second.
struct CheckCelebrationView: View {
    @Bindable var project: Project
    var onSeeReport: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showText = false
    @State private var confettiTrigger = 0

    private var result: ScoreEngine.Result { ScoreEngine.result(for: project) }

    /// Encouraging, warm copy by score band — never punishing, even at the low end.
    private var band: (headline: String, subtitle: String, sparkle: Bool) {
        switch result.overall {
        case 80...:
            return ("Amazing work!",
                    "This project clears the bar most apps miss. Share the report and keep it there.",
                    true)
        case 60..<80:
            return ("Getting there!",
                    "A solid, accessible foundation — a few focused fixes will push it into the green.",
                    true)
        default:
            return ("Great start!",
                    "You showed up and measured it — that's more than most teams ever do. Here's exactly what to tackle first.",
                    false)
        }
    }

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer(minLength: 0)

            ScoreRing(result: result)

            VStack(spacing: Spacing.md) {
                Text(band.headline)
                    .font(Typography.display)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                Text(band.subtitle)
                    .font(Typography.callout)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, Spacing.md)
            }
            .opacity(showText ? 1 : 0)
            .offset(y: showText ? 0 : 12)

            Spacer(minLength: 0)

            Button(action: onSeeReport) {
                HStack(spacing: Spacing.sm) {
                    Text("See Your Report")
                    Image(systemName: "arrow.right")
                }
                .font(Typography.headline)
                .foregroundStyle(ColorTokens.onBrand)
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(Capsule().fill(ColorTokens.brandPrimary))
            }
            .buttonStyle(.pressableCard)
            .opacity(showText ? 1 : 0)
            .accessibilityHint("Opens the detailed accessibility report")
        }
        .padding(Spacing.xl)
        .padding(.bottom, 100) // clear the floating tab bar
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AllyBackground(accent: ColorTokens.scoreColor(result.overall)))
        .overlay(ConfettiView(trigger: confettiTrigger))
        // For high scores under Reduce Motion, ConfettiView renders nothing; a
        // static sparkle keeps the moment celebratory without vestibular risk.
        .overlay(alignment: .top) {
            if band.sparkle && reduceMotion {
                Image(systemName: "sparkles")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(ColorTokens.celebration)
                    .padding(.top, Spacing.xxl)
                    .accessibilityHidden(true)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear(perform: run)
    }

    private func run() {
        // Headline fades in after the ring's sweep (ringFill ≈ 1.1s) settles.
        let delay = reduceMotion ? 0.15 : 0.9
        withAnimation(reduceMotion ? .easeInOut(duration: 0.2)
                                   : AnimationTokens.spring.delay(delay)) {
            showText = true
        }
        if band.sparkle {
            DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0 : 0.7)) {
                confettiTrigger += 1
                Haptics.success()
            }
        } else {
            Haptics.light()
        }
    }
}
