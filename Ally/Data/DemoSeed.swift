import Foundation
import SwiftData

/// Screenshot / demo helper. Seeds one realistic project (with answers and a
/// two-point history so the trend + "improved" celebration show) ONLY when the
/// app is launched with the `-seedDemo` argument. Inert in the shipping app.
enum DemoSeed {
    static let projectName = "Demo · Habits app"

    static func seedIfRequested(_ context: ModelContext) {
        guard CommandLine.arguments.contains("-seedDemo") else { return }
        let existing = try? context.fetch(FetchDescriptor<Project>())
        if existing?.contains(where: { $0.name == projectName }) == true { return }

        let project = Project(name: projectName, platform: .iOS)
        context.insert(project)

        // A plausible spread of answers.
        let answers: [String: Checkpoint.Answer] = [
            "v-contrast": .yes, "v-resize": .partially, "v-color": .yes, "v-alt": .no, "v-reflow": .partially,
            "m-target": .yes, "m-gesture": .partially, "m-undo": .no, "m-spacing": .yes, "m-timing": .notSure,
            "c-plain": .yes, "c-errors": .partially, "c-consistent": .yes, "c-predictable": .yes, "c-memory": .partially,
            "n-focus": .partially, "n-labels": .no, "n-headings": .yes, "n-location": .yes, "n-status": .partially
        ]
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
}
