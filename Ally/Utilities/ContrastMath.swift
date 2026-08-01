import SwiftUI
import UIKit

/// WCAG contrast math. Pure functions so the Contrast Checker and any future
/// caller (e.g. a self-audit of Ally's own tokens) share one implementation.
enum ContrastMath {

    /// Relative luminance per WCAG 2.x (sRGB → linear, weighted).
    static func luminance(_ color: Color) -> Double {
        let (r, g, b) = components(color)
        return luminance(r: r, g: g, b: b)
    }

    /// Contrast ratio between two colors, 1.0…21.0.
    static func ratio(_ a: Color, _ b: Color) -> Double {
        contrast(luminance(a), luminance(b))
    }

    // MARK: UIColor variants
    //
    // `Color` flattens to whatever trait collection happens to be current, which
    // is no good for adaptive tokens or for a test that has to check light *and*
    // dark. These take an already-resolved `UIColor` so the caller decides the
    // appearance.

    static func luminance(_ color: UIColor) -> Double {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return luminance(r: Double(r), g: Double(g), b: Double(b))
    }

    static func ratio(_ a: UIColor, _ b: UIColor) -> Double {
        contrast(luminance(a), luminance(b))
    }

    /// Resolves both colors for `style` first, so dynamic tokens are compared in
    /// the appearance you actually mean.
    static func ratio(_ a: Color, _ b: Color, in style: UIUserInterfaceStyle) -> Double {
        let traits = UITraitCollection(userInterfaceStyle: style)
        return ratio(UIColor(a).resolvedColor(with: traits),
                     UIColor(b).resolvedColor(with: traits))
    }

    private static func luminance(r: Double, g: Double, b: Double) -> Double {
        func lin(_ c: Double) -> Double {
            c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)
    }

    private static func contrast(_ la: Double, _ lb: Double) -> Double {
        let hi = max(la, lb), lo = min(la, lb)
        return (hi + 0.05) / (lo + 0.05)
    }

    /// WCAG pass thresholds for a given ratio.
    struct Verdict {
        let aaNormal: Bool      // ≥ 4.5
        let aaLarge: Bool       // ≥ 3.0
        let aaaNormal: Bool     // ≥ 7.0
        let aaaLarge: Bool      // ≥ 4.5
        let uiComponent: Bool   // ≥ 3.0 (1.4.11)
    }

    static func verdict(for ratio: Double) -> Verdict {
        Verdict(aaNormal: ratio >= 4.5, aaLarge: ratio >= 3.0,
                aaaNormal: ratio >= 7.0, aaaLarge: ratio >= 4.5,
                uiComponent: ratio >= 3.0)
    }

    /// Nudges `foreground` lighter or darker (whichever direction the background
    /// suggests) until it clears the AA-normal 4.5:1 bar, for the "suggest a fix"
    /// feature. Returns nil if it can't get there.
    static func suggestPassingForeground(foreground: Color, background: Color,
                                         target: Double = 4.5) -> Color? {
        let bgLum = luminance(background)
        let (r, g, b) = components(foreground)
        // If background is light, darken the foreground; else lighten it.
        let darken = bgLum > 0.5
        var factor = 1.0
        for _ in 0..<40 {
            factor += darken ? -0.025 : 0.025
            let nr = min(max(r * (darken ? factor : 1) + (darken ? 0 : (1 - r) * (factor - 1)), 0), 1)
            let ng = min(max(g * (darken ? factor : 1) + (darken ? 0 : (1 - g) * (factor - 1)), 0), 1)
            let nb = min(max(b * (darken ? factor : 1) + (darken ? 0 : (1 - b) * (factor - 1)), 0), 1)
            let candidate = Color(.sRGB, red: nr, green: ng, blue: nb)
            if ratio(candidate, background) >= target { return candidate }
        }
        return nil
    }

    /// sRGB 0…1 components via UIKit bridging.
    static func components(_ color: Color) -> (Double, Double, Double) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b))
    }

    /// Hex string like "#RRGGBB" for display.
    static func hexString(_ color: Color) -> String {
        let (r, g, b) = components(color)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
