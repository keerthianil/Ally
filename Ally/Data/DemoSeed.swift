import Foundation
import SwiftData

/// Screenshot / demo helper. Seeds one realistic project (with answers and a
/// two-point history so the trend + "improved" celebration show) ONLY when the
/// app is launched with the `-seedDemo` argument. Inert in the shipping app.
enum DemoSeed {
    static let projectName = "Demo · Habits app"

    static func seedIfRequested(_ context: ModelContext) {
        // `-resetStore` empties the store first. UI tests share one simulator and
        // SwiftData is persistent, so anything a test creates survives into the
        // next run: five identical "Checkout redesign" projects had piled up and
        // were failing a Voice Control ambiguity check that was correct to fail.
        // A test suite whose result depends on how many times it has been run is
        // not measuring the app.
        if CommandLine.arguments.contains("-resetStore") {
            if let all = try? context.fetch(FetchDescriptor<Project>()) {
                for project in all { context.delete(project) }
                try? context.save()
            }
        }

        guard CommandLine.arguments.contains("-seedDemo") else { return }
        let existing = try? context.fetch(FetchDescriptor<Project>())
        if existing?.contains(where: { $0.name == projectName }) == true { return }

        let project = Project(name: projectName, platform: .iOS)
        context.insert(project)

        let answers = answerSpread()
        for item in CheckpointBank.all {
            guard let ans = answers[item.id] else { continue }
            let cp = Checkpoint(itemID: item.id, category: item.category, answer: ans)
            cp.project = project
            project.checkpoints.append(cp)
            context.insert(cp)
        }

        let result = ScoreEngine.result(from: answers)

        // Older, weaker snapshot then today's improved one → shows the +delta.
        let older = CheckpointHistory(
            date: Calendar.current.date(byAdding: .day, value: -9, to: .now)!,
            score: max(0, result.overall - 14),
            visionScore: 55, motorScore: 60, cognitiveScore: 70, navigationScore: 48)
        older.project = project
        project.history.append(older)
        context.insert(older)

        let today = CheckpointHistory(
            score: result.overall,
            visionScore: result.score(for: .vision),
            motorScore: result.score(for: .motor),
            cognitiveScore: result.score(for: .cognitive),
            navigationScore: result.score(for: .navigation))
        today.project = project
        project.history.append(today)
        context.insert(today)

        try? context.save()
    }

    /// The answers to seed. `-seedBand <strong|building|starting>` picks a spread
    /// that lands in that score band, which is the only way to photograph all
    /// three celebration effects: each one is chosen by the score, so a single
    /// fixed demo project can only ever show one of them.
    private static func answerSpread() -> [String: Checkpoint.Answer] {
        let args = CommandLine.arguments
        let band = args.firstIndex(of: "-seedBand").flatMap { i -> String? in
            i + 1 < args.count ? args[i + 1] : nil
        }

        switch band {
        case "strong": // 88
            return [
                "v-contrast": .yes, "v-resize": .yes, "v-color": .yes, "v-alt": .yes, "v-reflow": .partially,
                "m-target": .yes, "m-gesture": .yes, "m-undo": .yes, "m-spacing": .yes, "m-timing": .partially,
                "c-plain": .yes, "c-errors": .yes, "c-consistent": .yes, "c-predictable": .yes, "c-memory": .yes,
                "n-focus": .yes, "n-labels": .yes, "n-headings": .partially, "n-location": .yes, "n-status": .partially
            ]
        case "starting": // 34
            return [
                "v-contrast": .partially, "v-resize": .no, "v-color": .no, "v-alt": .no, "v-reflow": .no,
                "m-target": .partially, "m-gesture": .no, "m-undo": .no, "m-spacing": .partially, "m-timing": .notSure,
                "c-plain": .yes, "c-errors": .no, "c-consistent": .partially, "c-predictable": .partially, "c-memory": .no,
                "n-focus": .no, "n-labels": .no, "n-headings": .partially, "n-location": .yes, "n-status": .no
            ]
        default: // 66, the plausible middle
            return [
                "v-contrast": .yes, "v-resize": .partially, "v-color": .yes, "v-alt": .no, "v-reflow": .partially,
                "m-target": .yes, "m-gesture": .partially, "m-undo": .no, "m-spacing": .yes, "m-timing": .notSure,
                "c-plain": .yes, "c-errors": .partially, "c-consistent": .yes, "c-predictable": .yes, "c-memory": .partially,
                "n-focus": .partially, "n-labels": .no, "n-headings": .yes, "n-location": .yes, "n-status": .partially
            ]
        }
    }
}
