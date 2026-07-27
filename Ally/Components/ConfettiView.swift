import SwiftUI

/// A one-shot confetti burst, drawn in a `Canvas` for performance. Bump `trigger`
/// to fire it. Under Reduce Motion it renders nothing (callers show a static
/// sparkle instead), so the celebration never becomes vestibular risk.
struct ConfettiView: View {
    var trigger: Int
    var duration: Double = 2.2
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var startDate: Date?

    private let palette: [Color] = [
        ColorTokens.brandPrimary, ColorTokens.brandSupport, ColorTokens.celebration,
        ColorTokens.vision, ColorTokens.cognitive, ColorTokens.navigation
    ]
    private let pieces: [Piece] = (0..<70).map { _ in Piece.random() }

    var body: some View {
        Group {
            if reduceMotion {
                Color.clear
            } else {
                TimelineView(.animation) { timeline in
                    Canvas { context, size in
                        guard let start = startDate else { return }
                        let t = timeline.date.timeIntervalSince(start)
                        guard t <= duration else { return }
                        let progress = t / duration
                        context.opacity = 1.0 - max(0, (progress - 0.7) / 0.3) // fade last 30%
                        for piece in pieces {
                            let x = size.width * piece.x + CGFloat(sin(t * piece.sway + piece.phase)) * 24
                            let y = -30 + CGFloat(progress) * (size.height + 60) * piece.speed
                            let angle = piece.spin * t
                            var rect = context
                            rect.translateBy(x: x, y: y)
                            rect.rotate(by: .radians(angle))
                            let r = CGRect(x: -piece.size / 2, y: -piece.size / 2,
                                           width: piece.size, height: piece.size * 0.5)
                            rect.fill(Path(roundedRect: r, cornerRadius: 1),
                                      with: .color(piece.color))
                        }
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: trigger) { _, _ in startDate = .now }
    }

    struct Piece {
        let x: CGFloat, size: CGFloat, speed: Double, spin: Double, sway: Double, phase: Double
        let color: Color
        static func random() -> Piece {
            let palette: [Color] = [
                ColorTokens.brandPrimary, ColorTokens.brandSupport, ColorTokens.celebration,
                ColorTokens.vision, ColorTokens.cognitive, ColorTokens.navigation
            ]
            return Piece(
                x: .random(in: 0...1),
                size: .random(in: 7...13),
                speed: .random(in: 0.6...1.2),
                spin: .random(in: -6...6),
                sway: .random(in: 1.5...3.5),
                phase: .random(in: 0...(2 * .pi)),
                color: palette.randomElement()!
            )
        }
    }
}
