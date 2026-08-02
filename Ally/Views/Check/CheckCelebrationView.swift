import SwiftUI

/// The moment of payoff. The score sweeps in on the signature ring, the band
/// reacts, and only then does the user tap through to the dense report.
/// Celebrate first, analyse second.
///
/// The reaction is band-specific in *energy*, never in approval. See
/// `CelebrationBand`: confetti at 42 out of 100 reads as sarcasm, but a low
/// score getting nothing at all reads as a verdict, and accessibility guilt is
/// the exact feeling this app exists to remove.
struct CheckCelebrationView: View {
    @Bindable var project: Project
    var onSeeReport: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showText = false
    @State private var confettiTrigger = 0

    private var result: ScoreEngine.Result { ScoreEngine.result(for: project) }

    private var band: CelebrationBand { CelebrationBand(score: result.overall) }

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
        .padding(.bottom, Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            ZStack {
                AllyBackground(accent: band.accent)
                // The score's own colour, washing down from the top behind the
                // ring. Green, orange, or red: the same three the ring, the band
                // label, and the project card all use, so the verdict is one
                // consistent thing rather than three coincidences.
                // Shorter than on the report: the effect owns the lower two
                // thirds of this screen and a full-height wash flattened it.
                ScoreWash(score: result.overall, height: 340)
            }
        }
        .overlay(CelebrationEffect(band: band, trigger: confettiTrigger))
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
        // The effect lands just after the ring settles, and the haptic weight
        // matches the visual weight rather than always being a success buzz.
        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0 : 0.7)) {
            confettiTrigger += 1
            band.playHaptic()
        }
    }
}
