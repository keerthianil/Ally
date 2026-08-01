import SwiftUI
import UIKit

/// Ally — "Grape Fizz", muted.
///
/// A caseless `enum` namespace of `static let` colors, same shape as the sibling
/// apps. Everything is declared inline as an adaptive `Color(light:dark:)` pair
/// rather than living in the asset catalog, so the whole system is readable in
/// one file and diffable in review.
///
/// The palette was desaturated in August 2026. The original was five saturated
/// hues plus a berry hero, which read as loud rather than confident and forced a
/// separate darkened ink for every single fill. Pulling saturation down turned
/// the category colours into pastels, and pastels carry the aubergine `ink` at
/// 7.4:1 to 8.6:1. The system got quieter and simpler at the same time.
///
/// Two rules govern it, both enforced by `ColorTokenContrastTests`:
///
/// 1. **A fill is not a text colour.** Every fill ships an `…Ink` variant, and
///    the ink is adaptive because a fixed one can only ever be right in one
///    appearance. It is also what any *information* graphic uses: a score arc
///    drawn in the pastel fill sits at 1.9:1 against its own track.
/// 2. **Text on a fill goes through `onFill(_:)`**, never a hardcoded white.
///    Post-muting it returns `ink` almost everywhere; berry is the one fill left
///    that white wins on.
enum ColorTokens {

    // MARK: - Brand

    /// Berry hero. Primary fills, tab accent, CTAs. The one saturated colour left
    /// in the system, and the only fill that carries white rather than ink.
    static let brandPrimary = Color(light: 0xB3338B, dark: 0xD478B7)
    /// Apricot support. Secondary emphasis and tints.
    static let brandSupport = Color(light: 0xE3AD86, dark: 0xDC7F3B)
    /// Butter celebration accent for streaks, sparkles, and score-up confetti.
    static let celebration = Color(light: 0xE4CB8A, dark: 0xE4CB8A)

    // MARK: - Brand inks (AA-safe text/links, adaptive)

    /// Berry as text. The muted hero is already dark enough to be read directly,
    /// so hero and hero-ink are the same value: one fewer thing to keep in sync.
    static let brandPrimaryInk = Color(light: 0xB3338B, dark: 0xD478B7)
    /// Apricot as text: burnt on light, warm on dark.
    static let brandSupportInk = Color(light: 0xB75005, dark: 0xDC7F3B)

    // MARK: - Surfaces

    /// App background. Warm blush cream, not white, so the pastel fills have
    /// something to sit against.
    static let surface = Color(light: 0xFAF4F6, dark: 0x1B1419)
    /// Elevated cards and sheets.
    static let surfaceElevated = Color(light: 0xFFFFFF, dark: 0x271C27)

    // MARK: - Text (system-adaptive so Dynamic Type + Increase Contrast just work)

    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let textTertiary = Color(.tertiaryLabel)

    /// Warm aubergine-black. The counterpart to white for text on a light fill,
    /// and after the palette was muted it is what `onFill` returns almost
    /// everywhere: the pastels carry it at 7.4:1 to 8.6:1.
    static let ink = Color(hex: 0x2A1B2E)

    /// Text/icons on top of a saturated fill. Picks white or `ink`, whichever wins
    /// on contrast against that fill *in the current appearance*.
    ///
    /// Returning a dynamic color rather than a resolved one matters: berry is
    /// `#B3338B` in light, where white wins at 5.59:1, and `#D478B7` in dark,
    /// where aubergine takes over.
    static func onFill(_ fill: Color) -> Color {
        Color(UIColor { traits in
            let bg = UIColor(fill).resolvedColor(with: traits)
            let inkUI = UIColor(ink)
            return ContrastMath.ratio(.white, bg) >= ContrastMath.ratio(inkUI, bg) ? .white : inkUI
        })
    }

    /// Text on the berry brand fill — by far the most common case.
    static var onBrand: Color { onFill(brandPrimary) }

    // MARK: - Borders / hairlines
    static let border = Color(light: 0xEADFE4, dark: 0x3A2C3A)

    // MARK: - Learn category colors (fill + AA text ink)

    // Fills are pastel and carry `ink` as text. Inks are the deep version of the
    // same hue, for small text and for any graphic that has to be *seen* rather
    // than merely felt: score arcs, bars, the category dot.

    /// Vision — dusty teal.
    static let vision = Color(light: 0x84C4D3, dark: 0x84C4D3)
    static let visionInk = Color(light: 0x0F7990, dark: 0x32ADC9)
    /// Motor — warm apricot (shares the support hue by design).
    static let motor = Color(light: 0xE3AD86, dark: 0xE3AD86)
    static let motorInk = Color(light: 0xB75005, dark: 0xDC7F3B)
    /// Cognitive — periwinkle.
    static let cognitive = Color(light: 0xC4B5E4, dark: 0xC4B5E4)
    static let cognitiveInk = Color(light: 0x7844F0, dark: 0x9A7BE1)
    /// Navigation — sage.
    static let navigation = Color(light: 0x7BBE93, dark: 0x7BBE93)
    static let navigationInk = Color(light: 0x197D3D, dark: 0x3AAD64)

    // MARK: - Semantic
    //
    // The plain tokens are *fills*, now pastel. Anything rendering one as text
    // uses the matching `…Ink`: sage reads at 2.0:1 on the cream surface, so it
    // is unusable as small text without the darkened variant.

    static let success = Color(light: 0x7BBE93, dark: 0x7BBE93)
    static let successInk = Color(light: 0x197D3D, dark: 0x3AAD64)
    static let error = Color(light: 0xDEA6A6, dark: 0xDEA6A6)
    static let errorInk = Color(light: 0xC02020, dark: 0xE58A8A)
    static let warning = Color(light: 0xD6AD68, dark: 0xD6AD68)
    static let warningInk = Color(light: 0x905E0A, dark: 0xD6AD68)
    static let info = Color(light: 0x84C4D3, dark: 0x84C4D3)
    static let infoInk = Color(light: 0x0F7990, dark: 0x32ADC9)

    // MARK: - Score bands (Check tab ring)

    /// Band *fill* for a 0–100 accessibility score — arcs, bars, dots.
    static func scoreColor(_ score: Int) -> Color {
        switch score {
        case 80...:   return success      // emerald
        case 60..<80: return brandSupport // tangerine
        default:      return error        // red
        }
    }

    /// Band color for *text* (the "Strong" / "Getting there" / "Needs work" label).
    static func scoreInk(_ score: Int) -> Color {
        switch score {
        case 80...:   return successInk
        case 60..<80: return brandSupportInk
        default:      return errorInk
        }
    }
}

// MARK: - Hex convenience

extension Color {
    /// Build an opaque `Color` from a 24-bit RGB hex literal, e.g. `Color(hex: 0xD6249F)`.
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1.0)
    }

    /// An appearance-aware color built from two hex literals. Used for the `…Ink`
    /// tokens, which have to move in opposite directions in the two appearances.
    init(light: UInt32, dark: UInt32) {
        self.init(UIColor { $0.userInterfaceStyle == .dark
            ? UIColor(Color(hex: dark))
            : UIColor(Color(hex: light)) })
    }
}
