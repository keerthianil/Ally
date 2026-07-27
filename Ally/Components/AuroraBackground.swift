import SwiftUI

/// A soft, living "aurora" made of blurred color blobs that drift slowly behind
/// hero content. iOS 17-safe (no `MeshGradient`) — it's just a few radial
/// gradients on a `TimelineView` clock. Honors Reduce Motion by freezing the
/// blobs in a pleasant static arrangement.
///
/// Pass the accent colors you want to bloom; Learn uses the four category hues so
/// the whole spectrum of accessibility is literally present in the backdrop.
struct AuroraBackground: View {
    var colors: [Color]
    var blur: CGFloat = 60
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { timeline in
            let t = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                context.addFilter(.blur(radius: blur))
                context.drawLayer { layer in
                    for (i, color) in colors.enumerated() {
                        let phase = Double(i) * 1.7
                        let cx = size.width  * (0.5 + 0.34 * cos(t * 0.18 + phase))
                        let cy = size.height * (0.42 + 0.30 * sin(t * 0.15 + phase * 1.3))
                        let r = min(size.width, size.height) * 0.55
                        let rect = CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)
                        let shading = GraphicsContext.Shading.radialGradient(
                            Gradient(colors: [color.opacity(0.55), color.opacity(0.0)]),
                            center: CGPoint(x: cx, y: cy),
                            startRadius: 0,
                            endRadius: r
                        )
                        layer.fill(Path(ellipseIn: rect), with: shading)
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }
}
