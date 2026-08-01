import Foundation

/// Cleans up model output so generated text reads like the rest of the app.
///
/// A language model writes in a recognisable register: em dashes everywhere,
/// "Additionally", hedges stacked on hedges, and a habit of restating the
/// question before answering it. None of that matches Ally's voice, and on a
/// screen that sits inches from hand-written copy the mismatch is obvious.
///
/// The model is *told* these rules in its instructions, which gets most of the
/// way. This is the part that doesn't rely on it complying.
enum HouseStyle {

    /// Everything, in the order the passes have to run.
    static func clean(_ text: String) -> String {
        var s = text
        s = stripDashes(s)
        s = stripPreamble(s)
        s = stripFiller(s)
        s = normalizeWhitespace(s)
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: Dashes

    /// No em dashes, anywhere. An en dash survives only between digits, where it
    /// is a numeric range (`4.5–7`) rather than punctuation.
    static func stripDashes(_ text: String) -> String {
        var out = ""
        let chars = Array(text)
        var i = 0
        while i < chars.count {
            let c = chars[i]
            guard c == "—" || c == "–" || c == "―" else { out.append(c); i += 1; continue }

            // Look at the neighbours, ignoring the spaces the dash may be padded with.
            var l = i - 1
            while l >= 0, chars[l] == " " { l -= 1 }
            var r = i + 1
            while r < chars.count, chars[r] == " " { r += 1 }
            let left = l >= 0 ? chars[l] : " "
            let right = r < chars.count ? chars[r] : " "

            if c == "–", left.isNumber, right.isNumber {
                out.append(c) // 4.5–7 is a range, leave it
                i += 1
                continue
            }

            // Trim any space we already emitted, then decide on comma or period.
            while out.last == " " { out.removeLast() }
            if out.last == "," || out.last == ":" || out.last == ";" {
                out.append(" ")
            } else if right.isUppercase {
                out.append(". ")
            } else {
                out.append(", ")
            }
            i = r
            continue
        }
        return out
    }

    // MARK: Preamble

    /// Drops the "Great question! Here's the answer:" opener.
    static func stripPreamble(_ text: String) -> String {
        var s = text
        let openers = [
            "great question", "good question", "that's a great question",
            "sure thing", "sure,", "certainly,", "absolutely,", "of course,",
            "based on the passages", "based on the provided passages",
            "based on the reference passages", "according to the passages",
            "from the passages", "the passages say", "the passages state",
            "based on the context", "according to the context",
            "here's the answer", "here is the answer", "in short,", "in summary,"
        ]
        var changed = true
        while changed {
            changed = false
            let lower = s.lowercased()
            for o in openers where lower.hasPrefix(o) {
                s = String(s.dropFirst(o.count))
                s = s.trimmingCharacters(in: CharacterSet(charactersIn: " ,.:!"))
                changed = true
                break
            }
        }
        // Re-capitalise if the trim ate the sentence's first letter case.
        if let f = s.first, f.isLowercase {
            s = s.replacingCharacters(in: s.startIndex...s.startIndex, with: String(f).uppercased())
        }
        return s
    }

    // MARK: Filler

    /// Swaps register-giveaway connectives for plainer ones. Ally teaches plain
    /// language (WCAG 3.1.5), so generated copy has to clear the bar it sets.
    static func stripFiller(_ text: String) -> String {
        var s = text
        let swaps: [(String, String)] = [
            ("Additionally, ", "Also, "),
            ("Furthermore, ", "And "),
            ("Moreover, ", "And "),
            ("However, it's important to note that ", "But "),
            ("It's important to note that ", ""),
            ("It is important to note that ", ""),
            ("It's worth noting that ", ""),
            ("Please note that ", ""),
            ("In order to ", "To "),
            ("Utilize ", "Use "),
            ("utilize ", "use "),
            ("Ensure that ", "Make sure "),
            ("ensure that ", "make sure "),
            ("delve into ", "look at "),
            ("leverage ", "use ")
        ]
        for (from, to) in swaps { s = s.replacingOccurrences(of: from, with: to) }
        return s
    }

    // MARK: Whitespace

    static func normalizeWhitespace(_ text: String) -> String {
        var s = text.replacingOccurrences(of: "\r\n", with: "\n")
        while s.contains("  ") { s = s.replacingOccurrences(of: "  ", with: " ") }
        while s.contains("\n\n\n") { s = s.replacingOccurrences(of: "\n\n\n", with: "\n\n") }
        s = s.replacingOccurrences(of: " ,", with: ",")
        s = s.replacingOccurrences(of: " .", with: ".")
        s = s.replacingOccurrences(of: ",,", with: ",")
        s = s.replacingOccurrences(of: ".,", with: ".")
        return s
    }

    /// The shared instruction fragment. Both the rewriter and the assistant use
    /// it, so the rules live in one place.
    static let voiceRules = """
        Voice rules, which matter as much as the content:
        - Never use an em dash or an en dash. Use a comma, a period, or restructure \
        the sentence. An en dash is allowed only between two numbers in a range.
        - Do not open with a greeting, a compliment, or a restatement of the question. \
        Answer directly.
        - Do not say "based on the passages", "according to the context", or refer to \
        being given reference material.
        - No "Additionally", "Furthermore", "Moreover", "it's important to note", \
        "delve", "leverage", or "utilize".
        - Short common words. Active voice. Speak to the reader as "you".
        - No bullet lists, no headings, no emoji, no markdown.
        """
}
