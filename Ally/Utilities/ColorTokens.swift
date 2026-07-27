import SwiftUI

/// Ally — "Grape Fizz" color system.
///
/// Architecture mirrors the Threadline/ARIA design-system DNA: a caseless `enum`
/// namespace of `static let` colors. Brand hues that need light/dark appearances
/// live in the asset catalog (`Color("…")`); fixed hues are declared inline as
/// `Color(hex:)`.
///
/// Rule for the whole app: every saturated *fill* color ships a darkened `…Ink`
/// variant that passes WCAG AA (≥4.5:1 on the app surface) so small text and links
/// stay legible. Ally teaches contrast — it must pass its own checks.
enum ColorTokens {

    // MARK: - Brand (asset catalog: light + dark appearances)

    /// Berry-magenta hero. Primary fills, tab accent, CTAs (white or ink text on top).
    static let brandPrimary = Color("BrandPrimary")
    /// Tangerine support. Secondary CTAs and highlights (dark/ink text on top).
    static let brandSupport = Color("BrandSupport")
    /// Golden celebration accent — streaks, sparkles, score-up confetti.
    static let celebration = Color("Celebration")

    // MARK: - Brand ink shortcuts (AA-safe text/links, hardcoded)

    /// Deep berry — magenta used as *text/links* on light surfaces (passes AA).
    static let brandPrimaryInk = Color(hex: 0xB0148A)
    /// Burnt tangerine — support color used as *text* on light surfaces.
    static let brandSupportInk = Color(hex: 0xC55A00)

    // MARK: - Surfaces (asset catalog: light + dark appearances)

    /// App background. Light: blush white `#FDF4FA`. Dark: `#180F1B`.
    static let surface = Color("Surface")
    /// Elevated cards/sheets. Light: `#FFFFFF`. Dark: `#241528`.
    static let surfaceElevated = Color("SurfaceElevated")

    // MARK: - Text (system-adaptive so Dynamic Type + Increase Contrast just work)

    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let textTertiary = Color(.tertiaryLabel)
    /// Text/icons placed on top of a saturated brand fill.
    static let onBrand = Color.white

    // MARK: - Borders / hairlines
    static let border = Color(.separator)

    // MARK: - Learn category colors (fill + AA text ink)

    /// Vision — cyan.
    static let vision = Color(hex: 0x12C2E9)
    static let visionInk = Color(hex: 0x0A93AE)
    /// Motor — tangerine (shares the support hue by design).
    static let motor = Color(hex: 0xFF7A18)
    static let motorInk = Color(hex: 0xC55A00)
    /// Cognitive — violet.
    static let cognitive = Color(hex: 0x8B5CF6)
    static let cognitiveInk = Color(hex: 0x6D3FE0)
    /// Navigation — emerald.
    static let navigation = Color(hex: 0x22C55E)
    static let navigationInk = Color(hex: 0x15803D)

    // MARK: - Semantic
    static let success = Color(hex: 0x22C55E)
    static let error = Color(hex: 0xEF4444)
    static let warning = Color(hex: 0xF59E0B)
    static let info = Color(hex: 0x12C2E9)

    // MARK: - Score bands (Check tab ring)
    /// Returns the band color for a 0–100 accessibility score.
    static func scoreColor(_ score: Int) -> Color {
        switch score {
        case 80...:   return success      // emerald
        case 60..<80: return brandSupport // tangerine
        default:      return error        // red
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
}
