import SwiftUI

/// Drag-to-reveal comparison. The "before" (inaccessible) version is the base;
/// dragging the handle wipes the accessible "after" version across it. Fully
/// accessible itself: exposed as an adjustable slider so VoiceOver users can move
/// the reveal with swipe up/down.
struct BeforeAfterSlider<Before: View, After: View>: View {
    var height: CGFloat = 150
    @ViewBuilder var before: Before
    @ViewBuilder var after: After

    @State private var fraction: CGFloat = 0.5
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let handleX = max(0, min(w, w * fraction))
            ZStack(alignment: .topLeading) {
                // BEFORE — base layer, tagged
                before
                    .frame(width: w, height: height)
                    .overlay(alignment: .topTrailing) { tag("Before", ColorTokens.error) }

                // AFTER — revealed from the left up to the handle
                after
                    .frame(width: w, height: height)
                    .overlay(alignment: .topLeading) { tag("After", ColorTokens.success) }
                    .mask(alignment: .leading) {
                        Rectangle().frame(width: handleX)
                    }

                // Handle
                handle
                    .position(x: handleX, y: height / 2)
            }
            .frame(width: w, height: height)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous))
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        fraction = max(0, min(1, value.location.x / w))
                    }
                    .onEnded { _ in Haptics.light() }
            )
        }
        .frame(height: height)
        // Accessibility: one adjustable control instead of a raw drag.
        .accessibilityElement(children: .contain)
        .accessibilityRepresentation {
            Slider(value: $fraction, in: 0...1)
                .accessibilityLabel("Before and after comparison")
                .accessibilityValue("\(Int(fraction * 100)) percent revealed")
        }
    }

    private var handle: some View {
        ZStack {
            Rectangle()
                .fill(ColorTokens.surfaceElevated)
                .frame(width: 3)
            Circle()
                .fill(ColorTokens.surfaceElevated)
                .frame(width: 40, height: 40)
                .shadow(color: .black.opacity(0.2), radius: 6, y: 2)
                .overlay(
                    Image(systemName: "arrow.left.and.right")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(ColorTokens.brandPrimaryInk)
                )
        }
        .frame(minWidth: 44, minHeight: 44) // keep the drag target ≥44pt
    }

    private func tag(_ text: String, _ color: Color) -> some View {
        Text(text.uppercased())
            .font(Typography.eyebrow)
            .foregroundStyle(.white)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .background(Capsule().fill(color))
            .padding(Spacing.sm)
    }
}
