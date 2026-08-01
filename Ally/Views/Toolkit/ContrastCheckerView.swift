import SwiftUI

/// Pick two colors → live WCAG ratio, a plain-English verdict, pass/fail badges
/// (each explained), and a one-tap auto-fix when it fails AA. Every number is
/// paired with words so a newcomer knows what to input, what the result means,
/// and what the fix does.
struct ContrastCheckerView: View {
    @State private var foreground: Color = Color(hex: 0x6B6B6B)
    @State private var background: Color = ColorTokens.surfaceElevated

    private var ratio: Double { ContrastMath.ratio(foreground, background) }
    private var verdict: ContrastMath.Verdict { ContrastMath.verdict(for: ratio) }

    /// One-line, plain-English reading of the ratio.
    private var plainVerdict: (text: String, color: Color) {
        switch ratio {
        case 7...:      return ("Excellent, passes even the strictest standard (AAA).", ColorTokens.successInk)
        case 4.5..<7:   return ("This passes the most common standard (AA).", ColorTokens.successInk)
        case 3..<4.5:   return ("Only large or bold text passes here, too low for body text.", ColorTokens.warningInk)
        default:        return ("This contrast is hard to read for many users.", ColorTokens.errorInk)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                intro
                previewSection
                ratioReadout
                if !verdict.aaNormal { fixButton }
                badges
                pickers
            }
            .padding(Spacing.xl)
            .padding(.bottom, Spacing.xxl)
        }
        .background(AllyBackground(accent: ColorTokens.vision))
        .scrollIndicators(.hidden)
        .navigationTitle("Contrast Checker")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Intro

    private var intro: some View {
        Text("Pick your text and background colors to check if they meet accessibility contrast standards.")
            .font(Typography.callout)
            .foregroundStyle(ColorTokens.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: Preview

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("PREVIEW")
                .font(Typography.eyebrow)
                .foregroundStyle(ColorTokens.textTertiary)
            preview
            Text("How your two colors look together.")
                .font(Typography.caption)
                .foregroundStyle(ColorTokens.textTertiary)
        }
    }

    private var preview: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("The quick brown fox")
                .font(.system(.title2, design: .rounded).weight(.bold))
            Text("Small body text jumps over the lazy dog to show how this pairing reads at a normal size.")
                .font(.subheadline)
        }
        .foregroundStyle(foreground)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.xl)
        .background(RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous).fill(background))
        .overlay(RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous).stroke(ColorTokens.border, lineWidth: 0.5))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Preview of the text color on the background color")
    }

    // MARK: Ratio + verdict

    private var ratioReadout: some View {
        VStack(spacing: Spacing.xs) {
            Text(String(format: "%.2f:1", ratio))
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .foregroundStyle(ColorTokens.textPrimary)
                .contentTransition(.numericText(value: ratio))
            Text("contrast ratio")
                .font(Typography.caption).foregroundStyle(ColorTokens.textSecondary)
            Text(plainVerdict.text)
                .font(Typography.subheadline.weight(.semibold))
                .foregroundStyle(plainVerdict.color)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Spacing.xxs)
        }
        .allyAnimation(AnimationTokens.snappy, value: ratio)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Contrast ratio \(String(format: "%.2f", ratio)) to 1. \(plainVerdict.text)")
    }

    // MARK: Auto-fix

    private var fixButton: some View {
        VStack(spacing: Spacing.xs) {
            Button {
                if let fixed = ContrastMath.suggestPassingForeground(foreground: foreground, background: background) {
                    withAnimation(AnimationTokens.spring) { foreground = fixed }
                    Haptics.success()
                }
            } label: {
                Label("Auto-fix to pass AA", systemImage: "wand.and.stars")
                    .font(Typography.headline).foregroundStyle(ColorTokens.onBrand)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(Capsule().fill(ColorTokens.brandPrimary))
            }
            .buttonStyle(.pressableCard)
            Text("Adjusts your text color to meet the AA standard while staying close to your original choice.")
                .font(Typography.caption)
                .foregroundStyle(ColorTokens.textTertiary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Badges

    private var badges: some View {
        VStack(spacing: Spacing.sm) {
            badge("AA · Normal text", "Regular body text (most common standard)", "4.5:1", verdict.aaNormal)
            badge("AA · Large text", "Headlines 18pt+ or bold 14pt+", "3:1", verdict.aaLarge)
            badge("AAA · Normal text", "Strictest standard for body text", "7:1", verdict.aaaNormal)
            badge("AAA · Large text", "Strictest standard for large text", "4.5:1", verdict.aaaLarge)
            badge("UI components & graphics", "Icons, borders, form controls", "3:1", verdict.uiComponent)
        }
    }

    private func badge(_ title: String, _ subtitle: String, _ threshold: String, _ pass: Bool) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: pass ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(pass ? ColorTokens.successInk : ColorTokens.errorInk)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(Typography.subheadline.weight(.semibold)).foregroundStyle(ColorTokens.textPrimary)
                Text(subtitle).font(Typography.caption2).foregroundStyle(ColorTokens.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: Spacing.sm)
            VStack(alignment: .trailing, spacing: 1) {
                Text(pass ? "Pass" : "Fail").font(Typography.footnote.weight(.bold))
                    .foregroundStyle(pass ? ColorTokens.successInk : ColorTokens.errorInk)
                Text(threshold).font(Typography.caption2).foregroundStyle(ColorTokens.textTertiary)
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous).fill(ColorTokens.surfaceElevated))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(subtitle): \(pass ? "pass" : "fail"), needs \(threshold)")
    }

    // MARK: Pickers

    private var pickers: some View {
        VStack(spacing: Spacing.md) {
            colorRow("Text Color", $foreground)
            colorRow("Background Color", $background)
        }
        .padding(Spacing.lg)
        .background(RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous).fill(ColorTokens.surfaceElevated))
    }

    private func colorRow(_ label: String, _ binding: Binding<Color>) -> some View {
        HStack(spacing: Spacing.sm) {
            Circle()
                .fill(binding.wrappedValue)
                .frame(width: 18, height: 18)
                .overlay(Circle().stroke(ColorTokens.border, lineWidth: 1))
                .accessibilityHidden(true)
            ColorPicker(selection: binding, supportsOpacity: false) {
                Text(label).font(Typography.bodyEmph).foregroundStyle(ColorTokens.textPrimary)
            }
            Spacer()
            Text(ContrastMath.hexString(binding.wrappedValue))
                .font(Typography.mono).foregroundStyle(ColorTokens.textSecondary)
        }
    }
}
