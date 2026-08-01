import SwiftUI

/// Enter a target's size → see whether it clears the iOS (44pt), Android (48dp),
/// and WCAG 2.5.8 (24px) minimums, with a to-scale visual so the gaps are obvious.
struct TouchTargetCalcView: View {
    @State private var width: Double = 32
    @State private var height: Double = 32

    private let iosMin: Double = 44
    private let androidMin: Double = 48
    private let wcagMin: Double = 24

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                intro
                visual
                legend
                sliders
                results
            }
            .padding(Spacing.xl)
            .padding(.bottom, Spacing.xxl)
        }
        .background(AllyBackground(accent: ColorTokens.motor))
        .scrollIndicators(.hidden)
        .navigationTitle("Touch Target")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var intro: some View {
        Text("Set a button's size to check it's easy to tap for everyone, including people with tremors or big fingers. Drag the sliders; the box updates live against each platform's minimum.")
            .font(Typography.callout)
            .foregroundStyle(ColorTokens.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// Names the dashed reference rings shown behind the live target.
    private var legend: some View {
        HStack(spacing: Spacing.lg) {
            legendItem(ColorTokens.success, "WCAG 24")
            legendItem(ColorTokens.warning, "iOS 44")
            legendItem(ColorTokens.error, "Android 48")
            Spacer(minLength: 0)
        }
        .accessibilityHidden(true) // the results list below conveys the same info to VoiceOver
    }

    private func legendItem(_ color: Color, _ label: String) -> some View {
        HStack(spacing: Spacing.xs) {
            RoundedRectangle(cornerRadius: 3)
                .stroke(color, style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
                .frame(width: 16, height: 16)
            Text(label).font(Typography.caption2).foregroundStyle(ColorTokens.textSecondary)
        }
    }

    private var visual: some View {
        ZStack {
            // Minimum reference rings, largest first.
            ref(androidMin, ColorTokens.error.opacity(0.35))
            ref(iosMin, ColorTokens.warning.opacity(0.5))
            ref(wcagMin, ColorTokens.success.opacity(0.4))
            // Actual target
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(ColorTokens.motor)
                .frame(width: width, height: height)
                .allyAnimation(AnimationTokens.snappy, value: width)
                .overlay(
                    Image(systemName: "hand.point.up.left.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                )
        }
        .frame(height: 180)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous).fill(ColorTokens.surfaceElevated))
        .accessibilityHidden(true)
    }

    private func ref(_ size: Double, _ color: Color) -> some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(color, style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
            .frame(width: size, height: size)
    }

    private var sliders: some View {
        VStack(spacing: Spacing.lg) {
            slider("Width", $width)
            slider("Height", $height)
        }
        .padding(Spacing.lg)
        .background(RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous).fill(ColorTokens.surfaceElevated))
    }

    private func slider(_ label: String, _ binding: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(label).font(Typography.bodyEmph).foregroundStyle(ColorTokens.textPrimary)
                Spacer()
                Text("\(Int(binding.wrappedValue)) pt").font(Typography.mono).foregroundStyle(ColorTokens.textSecondary)
            }
            Slider(value: binding, in: 12...80, step: 1)
                .tint(ColorTokens.motor)
                .accessibilityLabel(label)
                .accessibilityValue("\(Int(binding.wrappedValue)) points")
        }
    }

    private var results: some View {
        VStack(spacing: Spacing.sm) {
            row("Apple iOS HIG", iosMin, "44 pt")
            row("Android Material", androidMin, "48 dp")
            row("WCAG 2.5.8 (AA)", wcagMin, "24 px")
        }
    }

    private func row(_ name: String, _ minSize: Double, _ spec: String) -> some View {
        let pass = width >= minSize && height >= minSize
        return HStack {
            Image(systemName: pass ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(pass ? ColorTokens.success : ColorTokens.error)
            Text(name).font(Typography.subheadline).foregroundStyle(ColorTokens.textPrimary)
            Spacer()
            Text(spec).font(Typography.caption2).foregroundStyle(ColorTokens.textTertiary)
            Text(pass ? "Pass" : "Too small").font(Typography.footnote.weight(.bold))
                .foregroundStyle(pass ? ColorTokens.success : ColorTokens.error)
        }
        .padding(Spacing.md)
        .background(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous).fill(ColorTokens.surfaceElevated))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name), minimum \(spec): \(pass ? "pass" : "too small")")
    }
}
