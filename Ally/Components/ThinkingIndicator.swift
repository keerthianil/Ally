import SwiftUI

/// The waiting state for on-device generation.
///
/// Three dots in the category colors, easing in sequence. Kept quiet on purpose:
/// generation takes a second or two, and a big spinner would make a fast thing
/// feel slow. Under Reduce Motion the dots hold still at full opacity rather
/// than pulsing — the same rule the rest of the app follows, and the one Ally
/// teaches under WCAG 2.3.3.
struct ThinkingIndicator: View {
    var label: String = "Thinking"

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let dots: [Color] = [ColorTokens.visionInk, ColorTokens.cognitiveInk, ColorTokens.navigationInk]

    var body: some View {
        HStack(spacing: Spacing.sm) {
            if reduceMotion {
                ForEach(dots.indices, id: \.self) { i in
                    Circle().fill(dots[i]).frame(width: 8, height: 8)
                }
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    HStack(spacing: Spacing.sm) {
                        ForEach(dots.indices, id: \.self) { i in
                            let phase = t * 2.2 - Double(i) * 0.45
                            Circle()
                                .fill(dots[i])
                                .frame(width: 8, height: 8)
                                .opacity(0.35 + 0.65 * (0.5 + 0.5 * sin(phase)))
                        }
                    }
                }
                .frame(width: 8 * 3 + Spacing.sm * 2, height: 8)
            }

            Text(label)
                .font(Typography.footnote)
                .foregroundStyle(ColorTokens.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // The dots are decoration; the label carries the meaning. `updatesFrequently`
        // tells VoiceOver this element is in flux without it re-reading on every frame.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityAddTraits(.updatesFrequently)
    }
}

#Preview {
    ThinkingIndicator()
        .padding()
        .background(AllyBackground())
}
