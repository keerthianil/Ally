import SwiftUI
import UIKit

/// Ally — "Grape Fizz" color system.
///
/// Architecture mirrors the Threadline/ARIA design-system DNA: a caseless `enum`
/// namespace of `static let` colors. Brand hues that need light/dark appearances
/// live in the asset catalog (`Color("…")`); fixed hues are declared inline as
/// `Color(hex:)`.
///
/// Two rules govern the whole app, and `ColorTokenContrastTests` enforces both:
///
/// 1. **Every saturated fill ships an `…Ink` variant for text**, ≥4.5:1 on the app
///    surface. The ink is *adaptive*: on light it's a darkened version of the fill,
///    on dark it's usually the fill itself (a hue bright enough to read on `#180F1B`
///    is far too bright to read on `#FDF4FA`, and vice versa). A fixed ink can only
///    ever be correct in one appearance.
/// 2. **Text on a saturated fill goes through `onFill(_:)`**, never a hardcoded
///    white. White clears AA on berry-magenta and on the dark inks, and fails badly
///    on cyan (2.12:1), emerald (2.28:1), and tangerine (2.61:1).
enum ColorTokens {

    // MARK: - Brand (asset catalog: light + dark appearances)

    /// Berry-magenta hero. Primary fills, tab accent, CTAs (white or ink text on top).
    static let brandPrimary = Color("BrandPrimary")
    /// Tangerine support. Secondary CTAs and highlights (dark/ink text on top).
    static let brandSupport = Color("BrandSupport")
    /// Golden celebration accent — streaks, sparkles, score-up confetti.
    static let celebration = Color("Celebration")

    // MARK: - Brand inks (AA-safe text/links, adaptive)

    /// Berry used as *text/links*: deep berry on light, the bright brand hue on dark.
    static let brandPrimaryInk = Color(light: 0xB0148A, dark: 0xEC4FB4)
    /// Tangerine used as *text*: burnt on light, warm on dark.
    static let brandSupportInk = Color(light: 0xB25511, dark: 0xFF934A)

    // MARK: - Surfaces (asset catalog: light + dark appearances)

    /// App background. Light: blush white `#FDF4FA`. Dark: `#180F1B`.
    static let surface = Color("Surface")
    /// Elevated cards/sheets. Light: `#FFFFFF`. Dark: `#241528`.
    static let surfaceElevated = Color("SurfaceElevated")

    // MARK: - Text (system-adaptive so Dynamic Type + Increase Contrast just work)

    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let textTertiary = Color(.tertiaryLabel)

    /// Aubergine — the dark counterpart to white for text sitting on a light fill.
    static let ink = Color(hex: 0x221426)

    /// Text/icons on top of a saturated fill. Picks white or `ink`, whichever wins
    /// on contrast against that fill *in the current appearance*.
    ///
    /// Returning a dynamic color rather than a resolved one matters: the same chip
    /// is berry `#D6249F` in light (white text, 4.55:1) and `#EC4FB4` in dark, where
    /// white would drop to 3.31:1 and aubergine takes over at 5.30:1.
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
    static let border = Color(.separator)

    // MARK: - Learn category colors (fill + AA text ink)

    /// Vision — cyan.
    static let vision = Color(hex: 0x12C2E9)
    static let visionInk = Color(light: 0x0B7488, dark: 0x12C2E9)
    /// Motor — tangerine (shares the support hue by design).
    static let motor = Color(hex: 0xFF7A18)
    static let motorInk = Color(light: 0xB25511, dark: 0xFF934A)
    /// Cognitive — violet.
    static let cognitive = Color(hex: 0x8B5CF6)
    static let cognitiveInk = Color(light: 0x6D3FE0, dark: 0x9266F7)
    /// Navigation — emerald.
    static let navigation = Color(hex: 0x22C55E)
    static let navigationInk = Color(light: 0x15803D, dark: 0x22C55E)

    // MARK: - Semantic
    //
    // The plain tokens are *fills*. Anything that renders one as text uses the
    // matching `…Ink`: emerald reads at 2.12:1 on the light surface and amber at
    // 1.99:1, so neither is usable as small text without a darkened variant.

    static let success = Color(hex: 0x22C55E)
    static let successInk = Color(light: 0x16823E, dark: 0x22C55E)
    static let error = Color(hex: 0xEF4444)
    static let errorInk = Color(light: 0xCE3A3A, dark: 0xEF4444)
    static let warning = Color(hex: 0xF59E0B)
    static let warningInk = Color(light: 0x9D6507, dark: 0xF59E0B)
    static let info = Color(hex: 0x12C2E9)
    static let infoInk = Color(light: 0x0B7488, dark: 0x12C2E9)

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
