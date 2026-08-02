import XCTest
import SwiftUI
import UIKit
@testable import Ally

/// Ally's whole pitch is that it passes the rules it teaches. Before this test
/// existed that was an assertion, not a fact — the UI-test audit deliberately
/// skips `.contrast`, so nothing checked the palette, and six token pairs were
/// failing in one appearance or the other.
///
/// Every ratio here is recomputed from the shipping token values at test time via
/// `ContrastMath`, the same math the Toolkit's Contrast Checker shows the user. A
/// token change that regresses a pair fails the build.
final class ColorTokenContrastTests: XCTestCase {

    private let styles: [(UIUserInterfaceStyle, String)] = [(.light, "light"), (.dark, "dark")]

    /// The two backgrounds text can land on.
    private var surfaces: [(Color, String)] {
        [(ColorTokens.surface, "surface"), (ColorTokens.surfaceElevated, "surfaceElevated")]
    }

    /// Every token whose job is to be read as text on a surface.
    ///
    /// `ColorTokens.ink` is deliberately absent: it's the dark counterpart to white
    /// *on a fill*, never text on the app surface, so rule 2 is what covers it.
    private var inks: [(Color, String)] {
        [(ColorTokens.brandPrimaryInk, "brandPrimaryInk"),
         (ColorTokens.brandSupportInk, "brandSupportInk"),
         (ColorTokens.visionInk,       "visionInk"),
         (ColorTokens.motorInk,        "motorInk"),
         (ColorTokens.cognitiveInk,    "cognitiveInk"),
         (ColorTokens.navigationInk,   "navigationInk"),
         (ColorTokens.successInk,      "successInk"),
         (ColorTokens.errorInk,        "errorInk"),
         (ColorTokens.warningInk,      "warningInk"),
         (ColorTokens.infoInk,         "infoInk"),
         // The score bands broke out of the muted palette in August 2026 so the
         // three verdicts read as a traffic light. They still have to be legible.
         (ColorTokens.scoreStrongInk,  "scoreStrongInk"),
         (ColorTokens.scoreFairInk,    "scoreFairInk"),
         (ColorTokens.scoreWeakInk,    "scoreWeakInk")]
    }

    /// Tokens that actually sit behind text somewhere in the app.
    ///
    /// The saturated category fills are not in this list, and that's the design
    /// decision rather than an omission: none of them can carry legible text, so
    /// filled controls (chips, answer buttons) use the matching ink instead.
    private var textBearingFills: [(Color, String)] {
        [(ColorTokens.brandPrimary,    "brandPrimary"),
         (ColorTokens.textSecondary,   "textSecondary"),
         (ColorTokens.brandPrimaryInk, "brandPrimaryInk"),
         (ColorTokens.visionInk,       "visionInk"),
         (ColorTokens.motorInk,        "motorInk"),
         (ColorTokens.cognitiveInk,    "cognitiveInk"),
         (ColorTokens.navigationInk,   "navigationInk"),
         (ColorTokens.success,         "success"),
         (ColorTokens.error,           "error"),
         (ColorTokens.warning,         "warning"),
         // The destructive swipe action and the report's No pill are filled with
         // the ink rather than the pastel, because white on the pastel measured
         // about 2:1 — the exact failure the report was telling you to go fix.
         (ColorTokens.scoreWeakInk,    "scoreWeakInk"),
         (ColorTokens.warningInk,      "warningInk"),
         (ColorTokens.scoreStrongInk,  "scoreStrongInk"),
         (ColorTokens.scoreFairInk,    "scoreFairInk")]
    }

    // MARK: Rule 1 — every ink clears AA as body text, in both appearances

    func testInksClearAAOnBothSurfaces() {
        for (style, styleName) in styles {
            for (ink, inkName) in inks {
                for (surface, surfaceName) in surfaces {
                    let r = ContrastMath.ratio(ink, surface, in: style)
                    XCTAssertGreaterThanOrEqual(
                        r, 4.5,
                        "\(inkName) on \(surfaceName) in \(styleName) is \(fmt(r)):1 — needs 4.5:1 (WCAG 1.4.3)."
                    )
                }
            }
        }
    }

    // MARK: Rule 2 — onFill always finds a readable text color

    func testOnFillClearsAAAgainstEveryTextBearingFill() {
        for (style, styleName) in styles {
            for (fill, fillName) in textBearingFills {
                let r = ContrastMath.ratio(ColorTokens.onFill(fill), fill, in: style)
                XCTAssertGreaterThanOrEqual(
                    r, 4.5,
                    "onFill(\(fillName)) in \(styleName) is \(fmt(r)):1 — needs 4.5:1."
                )
            }
        }
    }

    /// The reason `onFill` exists rather than a hardcoded white: on a good part of
    /// the palette, white is the wrong answer.
    func testWhiteAloneWouldFailOnSomeFills() {
        let failures = textBearingFills.filter {
            ContrastMath.ratio(.white, $0.0, in: .light) < 4.5
        }.map(\.1)
        XCTAssertFalse(failures.isEmpty,
                       "If white cleared AA everywhere, onFill would be dead weight — delete it.")
    }

    // MARK: Rule 3 — score bands

    func testScoreInkIsReadableAsTextAndAsAnArc() {
        for (style, styleName) in styles {
            for score in [0, 45, 59, 60, 79, 80, 100] {
                for (surface, surfaceName) in surfaces {
                    let text = ContrastMath.ratio(ColorTokens.scoreInk(score), surface, in: style)
                    XCTAssertGreaterThanOrEqual(
                        text, 4.5,
                        "scoreInk(\(score)) on \(surfaceName) in \(styleName) is \(fmt(text)):1 — needs 4.5:1."
                    )
                    // The ring arc is a graphical object carrying the score, so
                    // 1.4.11's 3:1 applies — comfortably implied by the 4.5 above,
                    // asserted separately so the intent survives a refactor.
                    XCTAssertGreaterThanOrEqual(text, 3.0, "scoreInk(\(score)) fails 1.4.11.")
                }
            }
        }
    }

    // MARK: Rule 4 — an information graphic must separate from its own track
    //
    // This is the failure that motivated the whole file. The score ring draws each
    // category arc over a 15%-opacity track of the same hue. With the *fill* hue as
    // the arc, cyan managed 1.75:1 against its own track in light mode — invisible.
    // The arcs use the ink for exactly this reason.

    func testScoreArcsSeparateFromTheirTracks() {
        for (style, styleName) in styles {
            for category in AccessibilityCategory.allCases {
                for (surface, surfaceName) in surfaces {
                    let track = composite(category.color, alpha: 0.15, over: surface, in: style)
                    let arc = UIColor(category.inkColor)
                        .resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
                    let r = ContrastMath.ratio(arc, track)
                    XCTAssertGreaterThanOrEqual(
                        r, 3.0,
                        "\(category.rawValue) arc vs its track on \(surfaceName) in \(styleName) is \(fmt(r)):1 — needs 3:1 (WCAG 1.4.11)."
                    )
                }
            }
        }
    }

    // MARK: Rule 5 — the three score bands have to be told apart
    //
    // The muted palette was the right call everywhere except here. Sage, apricot
    // and dusty rose are three pastels of near-identical lightness, and at a
    // glance, in sunlight, or in peripheral vision they read as one beige. The
    // score is the only number the app produces, so its three bands are a real
    // traffic light now. This test is what stops them drifting back.

    func testScoreBandsAreVisuallyDistinctFromEachOther() {
        let bands: [(Color, String)] = [(ColorTokens.scoreStrong, "strong"),
                                        (ColorTokens.scoreFair,   "fair"),
                                        (ColorTokens.scoreWeak,   "weak")]
        for (style, styleName) in styles {
            for i in bands.indices {
                for j in bands.indices where j > i {
                    let d = distance(bands[i].0, bands[j].0, in: style)
                    XCTAssertGreaterThan(
                        d, 0.30,
                        "\(bands[i].1) and \(bands[j].1) are only \(fmt(d)) apart in \(styleName). "
                        + "Two score bands that close cannot be told apart at a glance."
                    )
                }
            }
        }
    }

    /// Colour is never allowed to carry the verdict on its own, so the band's
    /// name ships wherever the band's colour does.
    func testEveryScoreBandHasAName() {
        let names = [0, 49, 50, 79, 80, 100].map(ColorTokens.scoreLabel)
        XCTAssertEqual(Set(names).count, 3, "There should be exactly three named bands.")
        for n in names { XCTAssertFalse(n.isEmpty) }
    }

    /// Straight-line distance in sRGB. Crude next to a real perceptual metric,
    /// and entirely sufficient for "are these three obviously different".
    private func distance(_ a: Color, _ b: Color, in style: UIUserInterfaceStyle) -> Double {
        let traits = UITraitCollection(userInterfaceStyle: style)
        let x = UIColor(a).resolvedColor(with: traits)
        let y = UIColor(b).resolvedColor(with: traits)
        var xr: CGFloat = 0, xg: CGFloat = 0, xb: CGFloat = 0, xa: CGFloat = 0
        var yr: CGFloat = 0, yg: CGFloat = 0, yb: CGFloat = 0, ya: CGFloat = 0
        x.getRed(&xr, green: &xg, blue: &xb, alpha: &xa)
        y.getRed(&yr, green: &yg, blue: &yb, alpha: &ya)
        return sqrt(pow(xr - yr, 2) + pow(xg - yg, 2) + pow(xb - yb, 2))
    }

    /// Flattens `color` at `alpha` over `background`, the way the renderer does.
    private func composite(_ color: Color, alpha: CGFloat, over background: Color,
                           in style: UIUserInterfaceStyle) -> UIColor {
        let traits = UITraitCollection(userInterfaceStyle: style)
        let fg = UIColor(color).resolvedColor(with: traits)
        let bg = UIColor(background).resolvedColor(with: traits)
        var fr: CGFloat = 0, fg2: CGFloat = 0, fb: CGFloat = 0, fa: CGFloat = 0
        var br: CGFloat = 0, bg2: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        fg.getRed(&fr, green: &fg2, blue: &fb, alpha: &fa)
        bg.getRed(&br, green: &bg2, blue: &bb, alpha: &ba)
        return UIColor(red: fr * alpha + br * (1 - alpha),
                       green: fg2 * alpha + bg2 * (1 - alpha),
                       blue: fb * alpha + bb * (1 - alpha), alpha: 1)
    }

    // MARK: The math itself

    /// A known pair, so a bug in `ContrastMath` can't quietly make everything pass.
    func testKnownRatiosAreCorrect() {
        XCTAssertEqual(ContrastMath.ratio(UIColor.black, UIColor.white), 21.0, accuracy: 0.01)
        XCTAssertEqual(ContrastMath.ratio(UIColor.white, UIColor.white), 1.0, accuracy: 0.01)
    }

    private func fmt(_ r: Double) -> String { String(format: "%.2f", r) }
}
