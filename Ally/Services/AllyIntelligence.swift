import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// The single place the app asks "can we use the on-device model right now?".
///
/// Ally ships to iOS 17, and Foundation Models arrives in 26 on hardware that
/// supports Apple Intelligence — so for a large share of users the answer is no,
/// permanently. That isn't an error path bolted on at the end: the dictionary,
/// the Flesch-Kincaid math and the jargon list are the real product, and the
/// model is an accelerator on top. Every feature that touches it degrades to
/// something complete.
///
/// Everything funnels through `status` so there is exactly one `#available`
/// check to reason about, and one thing to fake when capturing screenshots.
enum AllyIntelligence {

    enum Status: Equatable {
        /// The model is loaded and ready.
        case ready
        /// iOS 17–25. No Foundation Models framework at all.
        case osTooOld
        /// iOS 26+, but this iPhone doesn't support Apple Intelligence.
        case deviceUnsupported
        /// Supported hardware with Apple Intelligence switched off in Settings.
        case notEnabled
        /// Enabled, but the model is still downloading.
        case modelNotReady

        var isReady: Bool { self == .ready }

        /// Plain-English, non-scolding. The user did nothing wrong, and in three
        /// of these four cases there is nothing they can do.
        var headline: String {
            switch self {
            case .ready:             return "On-device rewriting is on"
            case .osTooOld:          return "Needs iOS 26"
            case .deviceUnsupported: return "Not available on this iPhone"
            case .notEnabled:        return "Apple Intelligence is off"
            case .modelNotReady:     return "Still getting ready"
            }
        }

        var detail: String {
            switch self {
            case .ready:
                return "Text you write here is processed on your iPhone and never leaves it."
            case .osTooOld:
                return "Apple's on-device model arrived in iOS 26. Everything below still works without it."
            case .deviceUnsupported:
                return "Apple Intelligence needs newer hardware. Everything below still works without it."
            case .notEnabled:
                return "Turn it on in Settings › Apple Intelligence & Siri to get plain-language rewrites."
            case .modelNotReady:
                return "The model is still downloading. Check back shortly — everything below works meanwhile."
            }
        }

        /// Only `.notEnabled` is something the user can act on.
        var isActionable: Bool { self == .notEnabled }
    }

    /// Current availability, honoring the debug override.
    static var status: Status {
        if let forced = forcedStatus { return forced }
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                return .ready
            case .unavailable(.deviceNotEligible):
                return .deviceUnsupported
            case .unavailable(.appleIntelligenceNotEnabled):
                return .notEnabled
            case .unavailable(.modelNotReady):
                return .modelNotReady
            case .unavailable:
                return .deviceUnsupported
            }
        }
        #endif
        return .osTooOld
    }

    /// `-forceAIStatus <ready|osTooOld|deviceUnsupported|notEnabled|modelNotReady>`
    ///
    /// The unavailable states are as much a part of this design as the working
    /// one, and they're the states most users will see. This makes them
    /// reachable on any device so `ScreenshotCaptureTests` can capture them —
    /// the same trick `-openResult` and `-seedDemo` already use.
    ///
    /// Forcing `.ready` only changes what the UI *offers*; it can't conjure a
    /// model, so generation still fails over to the fallback copy.
    private static var forcedStatus: Status? {
        let args = CommandLine.arguments
        guard let i = args.firstIndex(of: "-forceAIStatus"), i + 1 < args.count else { return nil }
        switch args[i + 1] {
        case "ready":             return .ready
        case "osTooOld":          return .osTooOld
        case "deviceUnsupported": return .deviceUnsupported
        case "notEnabled":        return .notEnabled
        case "modelNotReady":     return .modelNotReady
        default:                  return nil
        }
    }
}
