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

// MARK: - Category stickers

/// Flat cut-out art, one per lens, drawn from primitives rather than imported.
///
/// Each is built from the same two-tone recipe (a pastel body in the category
/// fill, marks in the category ink) so four different drawings still read as one
/// set. Decorative, and hidden from VoiceOver.
struct CategorySticker: View {
    let category: AccessibilityCategory
    var size: CGFloat = 72
    /// Set when the sticker sits *on* a card painted in its own category hue.
    /// Without this the pastel body renders invisible against the pastel card
    /// and only the ink marks survive, which turned the eye into a blob and the
    /// tap target into an exclamation mark.
    var onCategoryFill: Bool = false

    var body: some View {
        Canvas { ctx, s in
            let w = s.width, h = s.height
            let fill = GraphicsContext.Shading.color(
                onCategoryFill ? Color.white.opacity(0.92) : category.color)
            let ink = GraphicsContext.Shading.color(category.inkColor)

            switch category {
            case .vision:
                // An eye: lens shape, iris, highlight.
                var eye = Path()
                eye.move(to: CGPoint(x: w * 0.06, y: h * 0.5))
                eye.addQuadCurve(to: CGPoint(x: w * 0.94, y: h * 0.5),
                                 control: CGPoint(x: w * 0.5, y: h * 0.06))
                eye.addQuadCurve(to: CGPoint(x: w * 0.06, y: h * 0.5),
                                 control: CGPoint(x: w * 0.5, y: h * 0.94))
                ctx.fill(eye, with: fill)
                ctx.fill(Path(ellipseIn: CGRect(x: w * 0.38, y: h * 0.32, width: w * 0.24, height: h * 0.36)), with: ink)
                ctx.fill(Path(ellipseIn: CGRect(x: w * 0.46, y: h * 0.38, width: w * 0.08, height: h * 0.10)),
                         with: .color(onCategoryFill ? category.color : .white.opacity(0.9)))

            case .motor:
                // A tap target: bullseye plus a ripple. An earlier version stacked
                // a fingertip above the ring and read as an exclamation mark.
                ctx.stroke(Path(ellipseIn: CGRect(x: w * 0.08, y: h * 0.08, width: w * 0.84, height: h * 0.84)),
                           with: fill, lineWidth: w * 0.11)
                ctx.stroke(Path(ellipseIn: CGRect(x: w * 0.26, y: h * 0.26, width: w * 0.48, height: h * 0.48)),
                           with: ink, lineWidth: w * 0.09)
                ctx.fill(Path(ellipseIn: CGRect(x: w * 0.40, y: h * 0.40, width: w * 0.20, height: h * 0.20)), with: ink)
                // A ripple off the top-right, so it reads as pressed rather than aimed at.
                var ripple = Path()
                ripple.addArc(center: CGPoint(x: w * 0.5, y: h * 0.5), radius: w * 0.56,
                              startAngle: .degrees(-70), endAngle: .degrees(-20), clockwise: false)
                ctx.stroke(ripple, with: fill, style: StrokeStyle(lineWidth: w * 0.07, lineCap: .round))

            case .cognitive:
                // Thought nodes orbiting a core.
                ctx.fill(Path(ellipseIn: CGRect(x: w * 0.30, y: h * 0.30, width: w * 0.40, height: h * 0.40)), with: fill)
                for (dx, dy, d) in [(0.50, 0.08, 0.16), (0.84, 0.42, 0.13), (0.16, 0.46, 0.13), (0.62, 0.84, 0.11)] {
                    ctx.fill(Path(ellipseIn: CGRect(x: w * dx - w * d / 2, y: h * dy - h * d / 2,
                                                    width: w * d, height: h * d)), with: ink)
                }

            case .navigation:
                // A route with a marker at the end.
                var route = Path()
                route.move(to: CGPoint(x: w * 0.12, y: h * 0.86))
                route.addCurve(to: CGPoint(x: w * 0.80, y: h * 0.24),
                               control1: CGPoint(x: w * 0.52, y: h * 0.92),
                               control2: CGPoint(x: w * 0.32, y: h * 0.24))
                ctx.stroke(route, with: fill, style: StrokeStyle(lineWidth: w * 0.13, lineCap: .round))
                ctx.fill(Path(ellipseIn: CGRect(x: w * 0.66, y: h * 0.10, width: w * 0.28, height: h * 0.28)), with: ink)
                ctx.fill(Path(ellipseIn: CGRect(x: w * 0.75, y: h * 0.19, width: w * 0.10, height: h * 0.10)),
                         with: .color(onCategoryFill ? category.color : .white.opacity(0.9)))
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

#Preview {
    VStack(spacing: 24) {
        HStack(spacing: 16) {
            ForEach(AccessibilityCategory.allCases) { CategorySticker(category: $0) }
        }
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
