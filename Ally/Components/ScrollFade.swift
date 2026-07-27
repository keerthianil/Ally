import SwiftUI

extension View {
    /// A subtle fade on the trailing edge of a horizontal scroll row, signaling
    /// "there's more to the right" so users know a chip row is scrollable. The
    /// leading edge is left crisp so the first (often selected) chip stays solid.
    func horizontalScrollFade() -> some View {
        mask(
            LinearGradient(
                stops: [
                    .init(color: .black, location: 0.0),
                    .init(color: .black, location: 0.86),
                    .init(color: .clear, location: 1.0)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
}
