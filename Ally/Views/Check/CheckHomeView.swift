import SwiftUI
import SwiftData

/// Check tab home — a list of saved projects (each with its latest score) plus an
/// inviting empty state. Routes into the guided flow and the result screen via a
/// single navigation path so re-checks land back on the result cleanly.
struct CheckHomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Project.updatedAt, order: .reverse) private var projects: [Project]

    @State private var path: [CheckRoute] = []
    @State private var showingNew = false
    @State private var didAutoOpen = false
    @State private var projectToDelete: Project?

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    header
                    if projects.isEmpty {
                        EmptyCheckState { showingNew = true }
                    } else {
                        newButton
                        ForEach(projects) { project in
                            SwipeableProjectRow(
                                project: project,
                                onOpen: { open(project) },
                                onRequestDelete: { requestDelete(project) }
                            )
                        }
                    }
                }
                .padding(Spacing.xl)
                .padding(.top, Spacing.xxl)
                .padding(.bottom, 110)
            }
            .background(AllyBackground())
            .scrollIndicators(.hidden)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: CheckRoute.self) { route in
                switch route {
                case .flow(let project):
                    CheckpointFlowView(project: project) {
                        path = [.celebration(project)] // celebrate before the report
                    }
                case .celebration(let project):
                    CheckCelebrationView(project: project) {
                        path = [.result(project)] // "See Your Report" → the report
                    }
                case .result(let project):
                    ScoreResultView(project: project) {
                        path.append(.flow(project))
                    }
                }
            }
            .sheet(isPresented: $showingNew) {
                NewProjectView { name, platform in
                    let project = Project(name: name, platform: platform)
                    context.insert(project)
                    try? context.save()
                    path.append(.flow(project))
                }
            }
            .confirmationDialog(
                "Delete this check?",
                isPresented: Binding(get: { projectToDelete != nil },
                                     set: { if !$0 { projectToDelete = nil } }),
                presenting: projectToDelete
            ) { project in
                Button("Delete", role: .destructive) { delete(project) }
                Button("Cancel", role: .cancel) { projectToDelete = nil }
            } message: { _ in
                Text("This can't be undone.")
            }
            .onAppear { autoOpenIfNeeded() }
            .onChange(of: projects) { _, _ in autoOpenIfNeeded() }
        }
    }

    private func requestDelete(_ project: Project) {
        Haptics.warning()
        projectToDelete = project
    }

    private func delete(_ project: Project) {
        // Cascade rules on Project handle its checkpoints and history.
        context.delete(project)
        try? context.save()
        projectToDelete = nil
        Haptics.success()
    }

    /// Screenshot helper: jump straight to a seeded project's result (`-openResult`)
    /// or its celebration screen (`-openCelebration`).
    private func autoOpenIfNeeded() {
        guard !didAutoOpen,
              let p = projects.first(where: { !$0.checkpoints.isEmpty }) else { return }
        let args = CommandLine.arguments
        if args.contains("-openResult") {
            didAutoOpen = true
            path = [.result(p)]
        } else if args.contains("-openCelebration") {
            didAutoOpen = true
            path = [.celebration(p)]
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("SELF-ASSESSMENT")
                .font(Typography.eyebrow).foregroundStyle(ColorTokens.brandPrimaryInk)
            Text("Check")
                .font(Typography.display).foregroundStyle(ColorTokens.textPrimary)
            Text("Score any project across the four lenses — and watch it improve.")
                .font(Typography.callout).foregroundStyle(ColorTokens.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var newButton: some View {
        Button { showingNew = true } label: {
            Label("New check", systemImage: "plus")
                .font(Typography.headline).foregroundStyle(ColorTokens.onBrand)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(Capsule().fill(ColorTokens.brandPrimary))
        }
        .buttonStyle(.pressableCard)
    }

    private func open(_ project: Project) {
        path.append(project.checkpoints.isEmpty ? .flow(project) : .result(project))
    }
}

enum CheckRoute: Hashable {
    case flow(Project)
    case celebration(Project)
    case result(Project)
}

// MARK: - Swipe-to-delete row

/// Wraps a `ProjectCard` with a custom trailing swipe (the list is a bespoke
/// `ScrollView`, not a `List`, so `.swipeActions` isn't available). A VoiceOver
/// "Delete" action keeps the destructive path reachable without the gesture.
private struct SwipeableProjectRow: View {
    @Bindable var project: Project
    var onOpen: () -> Void
    var onRequestDelete: () -> Void

    @State private var offset: CGFloat = 0
    private let revealWidth: CGFloat = 92

    var body: some View {
        ZStack(alignment: .trailing) {
            deleteAction
            Button {
                if offset != 0 {
                    withAnimation(AnimationTokens.snappy) { offset = 0 }
                } else {
                    onOpen()
                }
            } label: {
                ProjectCard(project: project)
            }
            .buttonStyle(.pressableCard)
            .offset(x: offset)
            .highPriorityGesture(swipe)
        }
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous))
        .accessibilityAction(named: "Delete") { onRequestDelete() }
    }

    private var deleteAction: some View {
        Button {
            withAnimation(AnimationTokens.snappy) { offset = 0 }
            onRequestDelete()
        } label: {
            VStack(spacing: Spacing.xs) {
                Image(systemName: "trash.fill").font(.system(size: 20, weight: .bold))
                Text("Delete").font(Typography.caption2.weight(.bold))
            }
            .foregroundStyle(.white)
            .frame(width: revealWidth)
            .frame(maxHeight: .infinity)
            .background(ColorTokens.error)
        }
        .buttonStyle(.plain)
        .accessibilityHidden(true) // reached via the row's accessibility action instead
    }

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 14)
            .onChanged { value in
                let base = offset == 0 ? 0 : -revealWidth
                offset = min(0, max(-revealWidth, base + value.translation.width))
            }
            .onEnded { value in
                let open = (offset + (value.predictedEndTranslation.width - value.translation.width)) < -revealWidth / 2
                withAnimation(AnimationTokens.snappy) { offset = open ? -revealWidth : 0 }
                if open { Haptics.warning() }
            }
    }
}

// MARK: - Project card

private struct ProjectCard: View {
    @Bindable var project: Project

    private var latest: Int? { project.history.sorted { $0.date < $1.date }.last?.score }

    var body: some View {
        HStack(spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(project.name).font(Typography.headline)
                    .foregroundStyle(ColorTokens.textPrimary)
                Text("\(project.platform.rawValue) · \(project.updatedAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(Typography.footnote).foregroundStyle(ColorTokens.textSecondary)
            }
            Spacer(minLength: 0)
            if let latest {
                ZStack {
                    Circle().stroke(ColorTokens.scoreColor(latest).opacity(0.2), lineWidth: 5)
                        .frame(width: 52, height: 52)
                    Circle().trim(from: 0, to: CGFloat(latest) / 100)
                        .stroke(ColorTokens.scoreColor(latest), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 52, height: 52)
                    Text("\(latest)").font(Typography.subheadline.weight(.bold))
                        .foregroundStyle(ColorTokens.textPrimary)
                }
            } else {
                Text("Start").font(Typography.subheadline.weight(.semibold))
                    .foregroundStyle(ColorTokens.brandPrimaryInk)
            }
        }
        .padding(Spacing.lg)
        .background(RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
            .fill(ColorTokens.surfaceElevated))
        .overlay(RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
            .stroke(ColorTokens.border, lineWidth: 0.5))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(project.name), \(project.platform.rawValue)\(latest != nil ? ", score \(latest!)" : ", not started")")
    }
}

// MARK: - Empty state

private struct EmptyCheckState: View {
    var onStart: () -> Void
    var body: some View {
        VStack(spacing: Spacing.lg) {
            ZStack {
                ForEach(Array(AccessibilityCategory.allCases.enumerated()), id: \.element) { i, cat in
                    Circle().fill(cat.color.opacity(0.9))
                        .frame(width: 26, height: 26)
                        .offset(x: [-30, 30, -30, 30][i], y: [-30, -30, 30, 30][i])
                }
                Circle().fill(ColorTokens.surfaceElevated).frame(width: 44, height: 44)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(ColorTokens.brandPrimary)
            }
            .frame(height: 110)

            Text("Your first check awaits")
                .font(Typography.title2).foregroundStyle(ColorTokens.textPrimary)
            Text("Answer a few plain-English questions and get an accessibility score you can act on.")
                .font(Typography.callout).foregroundStyle(ColorTokens.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: onStart) {
                Label("Start a check", systemImage: "plus")
                    .font(Typography.headline).foregroundStyle(ColorTokens.onBrand)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Capsule().fill(ColorTokens.brandPrimary))
            }
            .buttonStyle(.pressableCard)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: CornerRadius.xxl, style: .continuous)
            .fill(ColorTokens.surfaceElevated.opacity(0.6)))
    }
}

#Preview {
    CheckHomeView()
        .modelContainer(for: [Project.self, Checkpoint.self, CheckpointHistory.self], inMemory: true)
}
