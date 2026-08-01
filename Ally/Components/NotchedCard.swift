import SwiftUI

/// A rounded rectangle with a soft bite taken out of one corner.
///
/// The notch is the shape the whole Learn tab hangs on. It does two useful
/// things beyond looking less like a Bootstrap card: it gives every card an
/// unambiguous "front" so a grid of them reads as a stack of physical things,
/// and it leaves a reserved pocket for the corner glyph that would otherwise
/// float over the content.
struct NotchedCard: Shape {
    enum Corner { case topTrailing, topLeading }

    var corner: Corner = .topTrailing
    var radius: CGFloat = 26
    /// Diameter of the bite. Scales with the card so small cards don't get eaten.
    var notch: CGFloat = 46

    func path(in rect: CGRect) -> Path {
        let n = min(notch, min(rect.width, rect.height) * 0.42)
        let r = min(radius, min(rect.width, rect.height) / 2)
        var p = Path()

        // Build it as a rounded rect, then subtract a circle from the corner.
        p.addRoundedRect(in: rect, cornerSize: CGSize(width: r, height: r), style: .continuous)

        let centre: CGPoint
        switch corner {
        case .topTrailing: centre = CGPoint(x: rect.maxX - n * 0.30, y: rect.minY + n * 0.30)
        case .topLeading:  centre = CGPoint(x: rect.minX + n * 0.30, y: rect.minY + n * 0.30)
        }
        let bite = Path(ellipseIn: CGRect(x: centre.x - n / 2, y: centre.y - n / 2, width: n, height: n))
        return p.subtracting(bite)
    }
}

/// The glyph that sits in the notch. Deliberately a separate view so it can be
/// positioned in the hole rather than drawn into it.
struct NotchGlyph: View {
    let systemName: String
    var tint: Color
    var size: CGFloat = 40

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.42, weight: .bold))
            .foregroundStyle(ColorTokens.onFill(tint))
            .frame(width: size, height: size)
            .background(Circle().fill(tint))
            .accessibilityHidden(true)
    }
}

#Preview {
    VStack(spacing: 24) {
        ZStack(alignment: .topTrailing) {
            NotchedCard()
                .fill(ColorTokens.cognitive)
                .frame(width: 200, height: 160)
            NotchGlyph(systemName: "bookmark.fill", tint: ColorTokens.cognitiveInk)
                .offset(x: 6, y: -6)
        }
    }
    .padding(40)
    .background(ColorTokens.surface)
}
