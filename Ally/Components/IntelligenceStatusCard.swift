import SwiftUI

/// Shown wherever an on-device-model feature would be, when there's no model.
///
/// Deliberately not an error: no red, no warning triangle, no "unsupported".
/// It states what's unavailable, what still works, and — only when the user can
/// actually change it — how. Three of the four unavailable states are facts
/// about the hardware or OS, and offering a fix for those would be a lie.
struct IntelligenceStatusCard: View {
    let status: AllyIntelligence.Status
    /// One line naming what the user still gets. The fallback is the product.
    var fallbackNote: String

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(ColorTokens.brandPrimaryInk)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(status.headline)
                    .font(Typography.subheadline.weight(.semibold))
                    .foregroundStyle(ColorTokens.textPrimary)
                Text(status.detail)
                    .font(Typography.footnote)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(fallbackNote)
                    .font(Typography.footnote.weight(.semibold))
                    .foregroundStyle(ColorTokens.brandPrimaryInk)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
            Spacer(minLength: 0)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
            .fill(ColorTokens.surfaceElevated))
        .overlay(RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
            .stroke(ColorTokens.border, lineWidth: 0.5))
        // One element, read as one sentence — the icon is decorative and the
        // three lines are a single thought.
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(status.headline). \(status.detail) \(fallbackNote)")
    }

    private var symbol: String {
        switch status {
        case .ready:         return "apple.intelligence"
        case .modelNotReady: return "arrow.down.circle"
        case .notEnabled:    return "switch.2"
        default:             return "iphone.gen3"
        }
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        IntelligenceStatusCard(status: .notEnabled,
                               fallbackNote: "The grade level and jargon list below work either way.")
        IntelligenceStatusCard(status: .deviceUnsupported,
                               fallbackNote: "The grade level and jargon list below work either way.")
    }
    .padding()
    .background(AllyBackground())
}
