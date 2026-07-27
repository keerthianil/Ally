import SwiftUI

/// Ally typography — SF Pro **Rounded** for display/titles/headlines (playful,
/// Duolingo-adjacent), system default for body copy, monospaced for specs/hex.
///
/// Every token is built on a `Font.TextStyle`, so Dynamic Type scales the whole
/// hierarchy automatically. Never hardcode fixed point sizes on user-facing text —
/// use these tokens (or `.font(.body)` etc.) so the app respects Larger Text.
enum Typography {

    // MARK: - Display / titles (rounded, expressive)
    static let display = Font.system(.largeTitle, design: .rounded).weight(.heavy)
    static let title1   = Font.system(.title, design: .rounded).weight(.bold)
    static let title2   = Font.system(.title2, design: .rounded).weight(.bold)
    static let title3   = Font.system(.title3, design: .rounded).weight(.semibold)
    static let headline = Font.system(.headline, design: .rounded).weight(.semibold)

    // MARK: - Body / support (default design for readability)
    static let body        = Font.system(.body)
    static let bodyEmph    = Font.system(.body).weight(.semibold)
    static let callout     = Font.system(.callout)
    static let subheadline = Font.system(.subheadline)
    static let footnote    = Font.system(.footnote)
    static let caption     = Font.system(.caption)
    static let caption2    = Font.system(.caption2)

    // MARK: - Numeric / spec
    /// Big animated score numeral — rounded, heavy, monospaced digits so it
    /// doesn't jitter while counting up.
    static let scoreNumeral = Font.system(.largeTitle, design: .rounded)
        .weight(.heavy)
        .monospacedDigit()
    /// WCAG criterion IDs, hex codes, ratios.
    static let mono = Font.system(.subheadline, design: .monospaced).weight(.medium)

    // MARK: - Eyebrow label (small all-caps section tag)
    static let eyebrow = Font.system(.caption, design: .rounded).weight(.bold)
}
