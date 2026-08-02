import SwiftUI

/// A quick reference that is actually quick: a deck of flash cards.
///
/// Two rewrites got us here. The first version was a searchable list, which is a
/// fine *reference* and a poor *quick* reference. The second put a POUR map on
/// top of that list, which helped you choose a section and then handed you the
/// same wall of prose. Both had the same flaw, which is that they asked you to
/// read in order to find, when the thing you want from a reference is to
/// recognise.
///
/// So: one criterion on screen at a time, three short lines, and a flip.
///
/// - **Front.** The number, the level, the name, and the rule in one sentence.
/// - **Back.** What to do, and the classic failure. Two lines.
///
/// That is the entire content model, enforced by `WCAGCriterion` only having
/// those fields. Everything deeper (who it affects, what to change in SwiftUI,
/// how to test it) lives one tap away in Learn, which is the tab built for
/// reading. A reference and a dictionary are different jobs and this app now
/// stops pretending otherwise.
///
/// The flip is not decoration. Turning the rule over to get the fix is the
/// oldest revision mechanic there is, and it is the reason a deck beats a list
/// for something you are trying to hold in your head rather than look up once.
///
/// Nothing here depends on the swipe. Previous, Flip, and Next are real buttons,
/// because a gesture-only deck would fail WCAG 2.5.1 in an app about WCAG 2.5.1.
struct WCAGReferenceView: View {
    @State private var index = 0
    @State private var flipped = false
    @State private var query = ""
    @State private var principleFilter: WCAGCriterion.Principle?
    @State private var levelFilter: WCAGCriterion.Level?
    @State private var showingIndex = false
    @State private var learnTopic: LearnTopic?
    @FocusState private var searchFocused: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var deck: [WCAGCriterion] {
        WCAGReference.all.filter { c in
            (principleFilter == nil || c.principle == principleFilter) &&
            (levelFilter == nil || c.level == levelFilter) &&
            (query.isEmpty ||
             c.title.localizedCaseInsensitiveContains(query) ||
             c.id.contains(query) ||
             c.summary.localizedCaseInsensitiveContains(query) ||
             c.mustDo.localizedCaseInsensitiveContains(query))
        }
    }

    private var current: WCAGCriterion? {
        guard !deck.isEmpty else { return nil }
        return deck[min(index, deck.count - 1)]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                intro
                searchField
                principleRow
                levelRow

                if let current {
                    deckPosition
                    FlashCard(criterion: current,
                              flipped: $flipped,
                              reduceMotion: reduceMotion,
                              onOpenLearn: { openLearn(current) },
                              onNext: { step(1) },
                              onPrevious: { step(-1) })
                        .id(current.id)
                        .transition(reduceMotion ? .opacity : .asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)))
                    controls
                    indexSection
                } else {
                    emptyState
                }
            }
            .padding(Spacing.xl)
            .padding(.bottom, Spacing.xxl)
        }
        .background(
            AllyBackground(accent: current.map(color(for:)) ?? ColorTokens.navigation)
                .contentShape(Rectangle())
                .onTapGesture { searchFocused = false }
        )
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle("WCAG Quick Reference")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $learnTopic) { topic in NavigationStack { TopicDetailView(topic: topic) } }
    }

    // MARK: Header

    private var intro: some View {
        Text("\(WCAGReference.all.count) criteria, one card each. Flip for the fix. Tap through to Learn for the why.")
            .font(Typography.callout)
            .foregroundStyle(ColorTokens.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var searchField: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(ColorTokens.textTertiary)
                .accessibilityHidden(true)
            TextField("Search, or type a number", text: $query)
                .font(Typography.body)
                .focused($searchFocused)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(.search)
                .accessibilityLabel("Search criteria")
                .accessibilityHint("Narrows the deck by name, criterion number, or what to do")
                .onChange(of: query) { _, _ in resetDeck() }
            if !query.isEmpty {
                Button {
                    withAnimation(AnimationTokens.snappy) { query = "" }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(ColorTokens.textTertiary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, Spacing.md)
        .frame(minHeight: 50)
        .background(Capsule().fill(ColorTokens.surfaceElevated))
        .overlay(Capsule().stroke(ColorTokens.border, lineWidth: 1))
    }

    // MARK: Narrowing the deck
    //
    // The two things you already know when you arrive: roughly where in POUR the
    // problem sits, and roughly how strict you have to be. Both are one row of
    // chips rather than a screen of their own.

    private var principleRow: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("WHICH PART OF POUR")
                .font(Typography.eyebrow)
                .foregroundStyle(ColorTokens.textTertiary)
                .accessibilityAddTraits(.isHeader)
            HStack(spacing: Spacing.sm) {
                chip(title: "All",
                     count: WCAGReference.all.count,
                     tint: ColorTokens.brandPrimaryInk,
                     selected: principleFilter == nil,
                     label: "All principles") {
                    principleFilter = nil
                }
                ForEach(WCAGCriterion.Principle.allCases) { p in
                    chip(title: p.initial,
                         count: WCAGReference.criteria(for: p).count,
                         tint: color(for: p),
                         selected: principleFilter == p,
                         label: "\(p.rawValue). \(p.blurb)") {
                        principleFilter = (principleFilter == p) ? nil : p
                    }
                }
            }
        }
    }

    private var levelRow: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("HOW STRICT")
                .font(Typography.eyebrow)
                .foregroundStyle(ColorTokens.textTertiary)
                .accessibilityAddTraits(.isHeader)
            HStack(spacing: Spacing.sm) {
                chip(title: "Any", count: WCAGReference.all.count,
                     tint: ColorTokens.brandPrimaryInk,
                     selected: levelFilter == nil, label: "Any level") {
                    levelFilter = nil
                }
                ForEach(WCAGCriterion.Level.allCases) { l in
                    chip(title: l.rawValue, count: WCAGReference.count(level: l),
                         tint: levelColor(l), selected: levelFilter == l,
                         label: "Level \(l.rawValue), \(l.meaning)") {
                        levelFilter = (levelFilter == l) ? nil : l
                    }
                }
            }
        }
    }

    private func chip(title: String, count: Int, tint: Color, selected: Bool,
                      label: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.selection()
            withAnimation(AnimationTokens.snappy) { action(); resetDeck() }
        } label: {
            VStack(spacing: 0) {
                Text(title)
                    .font(Typography.subheadline.weight(.bold))
                    .lineLimit(1).minimumScaleFactor(0.7)
                Text("\(count)")
                    .font(Typography.caption2.weight(.semibold))
                    .monospacedDigit()
                    .opacity(0.8)
            }
            .foregroundStyle(selected ? ColorTokens.onFill(tint) : ColorTokens.textSecondary)
            .padding(.horizontal, Spacing.xs)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                .fill(selected ? tint : ColorTokens.surfaceElevated))
            .overlay(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                .stroke(selected ? Color.clear : ColorTokens.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label), \(count) criteria")
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: Position in the deck

    private var deckPosition: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text("CARD \(min(index, max(deck.count - 1, 0)) + 1) OF \(deck.count)")
                    .font(Typography.eyebrow)
                    .foregroundStyle(ColorTokens.textTertiary)
                    .monospacedDigit()
                Spacer()
                if principleFilter != nil || levelFilter != nil || !query.isEmpty {
                    Button {
                        Haptics.light()
                        withAnimation(AnimationTokens.snappy) {
                            principleFilter = nil; levelFilter = nil; query = ""
                            resetDeck()
                        }
                        searchFocused = false
                    } label: {
                        Text("Show all \(WCAGReference.all.count)")
                            .font(Typography.footnote.weight(.semibold))
                            .foregroundStyle(ColorTokens.brandPrimaryInk)
                            .padding(.horizontal, Spacing.sm)
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                    }
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(ColorTokens.border.opacity(0.5))
                    Capsule()
                        .fill(current.map(color(for:)) ?? ColorTokens.brandPrimary)
                        .frame(width: max(6, geo.size.width * CGFloat(index + 1) / CGFloat(max(deck.count, 1))))
                        .allyAnimation(AnimationTokens.snappy, value: index)
                }
            }
            .frame(height: 6)
            .accessibilityHidden(true) // the eyebrow above already says the position
        }
    }

    // MARK: Controls
    //
    // The deck's real interface. The swipe on the card is a shortcut layered on
    // top of these, never the other way round.

    private var controls: some View {
        HStack(spacing: Spacing.sm) {
            controlButton("Previous", "chevron.left", filled: false) { step(-1) }
                .disabled(deck.count < 2)

            Button {
                Haptics.light()
                withAnimation(flipAnimation) { flipped.toggle() }
            } label: {
                Label(flipped ? "Show the rule" : "Show the fix",
                      systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
                    .font(Typography.headline)
                    .foregroundStyle(ColorTokens.onBrand)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Capsule().fill(ColorTokens.brandPrimary))
            }
            .buttonStyle(.pressableCard)

            controlButton("Next", "chevron.right", filled: false) { step(1) }
                .disabled(deck.count < 2)
        }
    }

    private func controlButton(_ title: String, _ symbol: String, filled: Bool,
                               action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(ColorTokens.brandPrimaryInk)
                .frame(width: 50, height: 50)
                .background(Circle().fill(ColorTokens.surfaceElevated))
                .overlay(Circle().stroke(ColorTokens.border, lineWidth: 1))
        }
        .buttonStyle(.pressableCard)
        .accessibilityLabel(title)
    }

    // MARK: The index
    //
    // A dense grid of numbers, which is the other way people use a reference:
    // not browsing, but going straight to the one they already have in mind.
    // Collapsed by default so it never competes with the card.

    private var indexSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Button {
                Haptics.selection()
                withAnimation(AnimationTokens.snappy) { showingIndex.toggle() }
            } label: {
                HStack {
                    Text(showingIndex ? "Hide the index" : "Jump to a number")
                        .font(Typography.subheadline.weight(.semibold))
                        .foregroundStyle(ColorTokens.brandPrimaryInk)
                    Spacer()
                    Image(systemName: showingIndex ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(ColorTokens.brandPrimaryInk)
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(showingIndex ? "Collapses the list of criterion numbers"
                                            : "Expands a grid of every criterion number in this deck")

            if showingIndex {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.sm), count: 4),
                          spacing: Spacing.sm) {
                    ForEach(Array(deck.enumerated()), id: \.element.id) { i, c in
                        Button {
                            Haptics.selection()
                            withAnimation(AnimationTokens.snappy) {
                                index = i
                                flipped = false
                            }
                        } label: {
                            VStack(spacing: 1) {
                                Text(c.id)
                                    .font(Typography.mono)
                                    .lineLimit(1).minimumScaleFactor(0.7)
                                Text(c.level.rawValue)
                                    .font(Typography.caption2.weight(.bold))
                                    .opacity(0.75)
                            }
                            .foregroundStyle(i == index ? ColorTokens.onFill(color(for: c))
                                                        : ColorTokens.textPrimary)
                            .frame(maxWidth: .infinity, minHeight: 46)
                            .background(RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous)
                                .fill(i == index ? color(for: c) : color(for: c).opacity(0.16)))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(c.id), \(c.title), level \(c.level.rawValue)")
                        .accessibilityAddTraits(i == index ? [.isButton, .isSelected] : .isButton)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.xs) {
            Text("No card matches that")
                .font(Typography.headline).foregroundStyle(ColorTokens.textPrimary)
            Text("Ally covers \(WCAGReference.all.count) criteria, not all of WCAG. Try a broader word, or clear the filters.")
                .font(Typography.subheadline).foregroundStyle(ColorTokens.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Button("Show all \(WCAGReference.all.count)") {
                Haptics.light()
                withAnimation(AnimationTokens.snappy) {
                    principleFilter = nil; levelFilter = nil; query = ""
                    resetDeck()
                }
            }
            .font(Typography.subheadline.weight(.semibold))
            .foregroundStyle(ColorTokens.onBrand)
            .padding(.horizontal, Spacing.lg)
            .frame(minHeight: 44)
            .background(Capsule().fill(ColorTokens.brandPrimary))
            .padding(.top, Spacing.sm)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }

    // MARK: Deck mechanics

    private var flipAnimation: Animation {
        reduceMotion ? AnimationTokens.reducedFallback : .spring(response: 0.48, dampingFraction: 0.82)
    }

    /// Wraps at both ends. A deck you can fall off the end of makes the last card
    /// feel like an error rather than a lap.
    private func step(_ delta: Int) {
        guard deck.count > 1 else { return }
        Haptics.selection()
        withAnimation(reduceMotion ? AnimationTokens.reducedFallback : AnimationTokens.spring) {
            index = (index + delta + deck.count) % deck.count
            flipped = false
        }
    }

    private func resetDeck() {
        index = 0
        flipped = false
    }

    private func openLearn(_ c: WCAGCriterion) {
        guard let id = c.learnTopicID else { return }
        learnTopic = LearnContent.topic(id: id)
    }

    // MARK: Colour

    private func color(for c: WCAGCriterion) -> Color { color(for: c.principle) }

    private func color(for p: WCAGCriterion.Principle) -> Color {
        switch p {
        case .perceivable:    return ColorTokens.vision
        case .operable:       return ColorTokens.motor
        case .understandable: return ColorTokens.cognitive
        case .robust:         return ColorTokens.navigation
        }
    }

    private func levelColor(_ level: WCAGCriterion.Level) -> Color {
        switch level {
        case .a:   return ColorTokens.successInk
        case .aa:  return ColorTokens.brandSupportInk
        case .aaa: return ColorTokens.cognitiveInk
        }
    }
}

// MARK: - The card

/// One criterion, front and back.
///
/// The number leads and is monospaced, because a criterion id is the thing people
/// scan for and a column of aligned digits is far faster to read than the same
/// numbers set in the body face. Everything else on the front is one sentence.
private struct FlashCard: View {
    let criterion: WCAGCriterion
    @Binding var flipped: Bool
    let reduceMotion: Bool
    var onOpenLearn: () -> Void
    var onNext: () -> Void
    var onPrevious: () -> Void

    private var tint: Color {
        switch criterion.principle {
        case .perceivable:    return ColorTokens.vision
        case .operable:       return ColorTokens.motor
        case .understandable: return ColorTokens.cognitive
        case .robust:         return ColorTokens.navigation
        }
    }

    private var ink: Color {
        switch criterion.principle {
        case .perceivable:    return ColorTokens.visionInk
        case .operable:       return ColorTokens.motorInk
        case .understandable: return ColorTokens.cognitiveInk
        case .robust:         return ColorTokens.navigationInk
        }
    }

    var body: some View {
        ZStack {
            front
                .opacity(flipped ? 0 : 1)
                .accessibilityHidden(flipped)
                .allowsHitTesting(!flipped)
            back
                .opacity(flipped ? 1 : 0)
                // Counter-rotated so the back reads the right way round once the
                // card has turned.
                .rotation3DEffect(.degrees(reduceMotion ? 0 : 180), axis: (x: 0, y: 1, z: 0))
                // An `.opacity(0)` view is still hit-testable and still in the
                // tree. The back's "The why, in Learn" button was therefore live
                // and focusable underneath the *front* of the card: a tap near
                // the bottom of a face-up card opened a Learn sheet instead of
                // flipping, and VoiceOver offered a button that was not there.
                .accessibilityHidden(!flipped)
                .allowsHitTesting(flipped)
        }
        .frame(maxWidth: .infinity, minHeight: 296, alignment: .topLeading)
        .background(NotchedCard(notch: 54).fill(tint))
        // The notch and the badge ride the container, so turning the card moves
        // them to the other corner. That is correct card physics and it is left
        // alone; only the letter is counter-rotated, so it never renders
        // mirrored, and the back reserves its clearance on the matching side.
        .overlay(alignment: .topTrailing) {
            levelBadge
                .rotation3DEffect(.degrees(flipped && !reduceMotion ? 180 : 0),
                                  axis: (x: 0, y: 1, z: 0))
                .offset(x: 3, y: -3)
        }
        .rotation3DEffect(.degrees(flipped && !reduceMotion ? 180 : 0),
                          axis: (x: 0, y: 1, z: 0), perspective: 0.4)
        .contentShape(Rectangle())
        .onTapGesture {
            Haptics.light()
            withAnimation(reduceMotion ? AnimationTokens.reducedFallback
                                       : .spring(response: 0.48, dampingFraction: 0.82)) {
                flipped.toggle()
            }
        }
        // Swipe is a shortcut on top of the Previous and Next buttons, never the
        // only route (WCAG 2.5.1).
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    guard abs(value.translation.width) > abs(value.translation.height) else { return }
                    value.translation.width < 0 ? onNext() : onPrevious()
                }
        )
        // One element, one utterance. VoiceOver should not have to reconstruct a
        // card from six fragments, and the actions are how it flips and moves.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenLabel)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Double tap to \(flipped ? "show the rule" : "show the fix")")
        // The default action, explicitly. The card is a plain view with an
        // `onTapGesture`, not a Button, and VoiceOver's double tap sends an
        // activate action that a bare tap gesture does not reliably receive. The
        // hint above promises a double tap works, so it has to.
        .accessibilityAction {
            withAnimation(AnimationTokens.reducedFallback) { flipped.toggle() }
        }
        .accessibilityAction(named: flipped ? "Show the rule" : "Show the fix") {
            withAnimation(AnimationTokens.reducedFallback) { flipped.toggle() }
        }
        .accessibilityAction(named: "Next card") { onNext() }
        .accessibilityAction(named: "Previous card") { onPrevious() }
        .accessibilityAction(named: "Open in Learn") { onOpenLearn() }
    }

    private var spokenLabel: String {
        let head = "\(criterion.id), \(criterion.title). Level \(criterion.level.rawValue), \(criterion.level.meaning). \(criterion.principle.rawValue)."
        return flipped
            ? "\(head) What to do: \(criterion.mustDo) Classic failure: \(criterion.redFlag)"
            : "\(head) \(criterion.summary)"
    }

    // MARK: Front

    private var front: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(criterion.id)
                .font(.system(.largeTitle, design: .monospaced).weight(.heavy))
                .foregroundStyle(ColorTokens.ink)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text(criterion.title)
                .font(Typography.title3)
                .foregroundStyle(ColorTokens.ink)
                .fixedSize(horizontal: false, vertical: true)

            Divider().overlay(ColorTokens.ink.opacity(0.22))

            Text(criterion.summary)
                .font(Typography.title3.weight(.regular))
                .foregroundStyle(ColorTokens.ink.opacity(0.88))
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: Spacing.sm)

            HStack(spacing: Spacing.xs) {
                Image(systemName: "hand.tap.fill").font(.system(size: 11, weight: .bold))
                Text("Tap for the fix")
                    .font(Typography.caption.weight(.semibold))
            }
            .foregroundStyle(ColorTokens.ink.opacity(0.6))
        }
        .padding(Spacing.xl)
        .padding(.trailing, Spacing.lg) // clear the level badge in the notch
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    // MARK: Back

    private var back: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            backBlock(eyebrow: "DO THIS", symbol: "checkmark.circle.fill", text: criterion.mustDo)
            backBlock(eyebrow: "RED FLAG", symbol: "exclamationmark.triangle.fill", text: criterion.redFlag)

            Spacer(minLength: 0)

            // Built only while the card is actually turned over.
            //
            // `.opacity(0)`, `.allowsHitTesting(false)`, and `.accessibilityHidden`
            // on the face were all tried first and none of them stopped this
            // button being live underneath the front of the card, which meant a
            // tap near the bottom of a face-up card opened a Learn sheet instead
            // of flipping. Not building it is the only version that holds.
            if criterion.learnTopicID != nil && flipped {
                Button(action: onOpenLearn) {
                    HStack(spacing: Spacing.sm) {
                        Text("The why, in Learn")
                        Image(systemName: "arrow.up.forward")
                    }
                    .font(Typography.subheadline.weight(.bold))
                    .foregroundStyle(ColorTokens.onFill(ink))
                    .padding(.horizontal, Spacing.lg)
                    .frame(minHeight: 44)
                    .background(Capsule().fill(ink))
                }
                .buttonStyle(.pressableCard)
                // The card's own custom action already covers this for VoiceOver,
                // and two routes to one destination is one extra swipe per card.
                .accessibilityHidden(true)
            }
        }
        .padding(Spacing.xl)
        // Leading, not trailing: once the card has turned, the notch is on the
        // left, so that is the side that needs clearing.
        .padding(.leading, reduceMotion ? 0 : Spacing.lg)
        .padding(.trailing, reduceMotion ? Spacing.lg : 0)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func backBlock(eyebrow: String, symbol: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: symbol).font(.system(size: 11, weight: .bold))
                Text(eyebrow).font(Typography.eyebrow)
            }
            .foregroundStyle(ColorTokens.ink.opacity(0.62))
            Text(text)
                .font(Typography.title3.weight(.regular))
                .foregroundStyle(ColorTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// The level, living in the notch. A letter with no context is a puzzle, so
    /// the meaning rides along in the spoken label and in the filter chips.
    private var levelBadge: some View {
        Text(criterion.level.rawValue)
            .font(.system(.subheadline, design: .rounded).weight(.black))
            .foregroundStyle(ColorTokens.onFill(ink))
            .frame(width: 46, height: 46)
            .background(Circle().fill(ink))
            .accessibilityHidden(true)
    }
}

#Preview {
    NavigationStack { WCAGReferenceView() }
}
