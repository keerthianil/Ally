import SwiftUI
import SwiftData

@main
struct AllyApp: App {
    /// SwiftData stack for the Check tab. Learn content and Toolkit are static /
    /// stateless, so only assessment models live here.
    let container: ModelContainer = {
        let schema = Schema([Project.self, Checkpoint.self, CheckpointHistory.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    /// The app's only persisted preference. Everything else about Ally is either
    /// static content or lives in SwiftData.
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showOnboarding = false

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .tint(ColorTokens.brandPrimary)
                .task {
                    DemoSeed.seedIfRequested(container.mainContext)
                    showOnboarding = OnboardingGate.shouldShow(hasSeen: hasSeenOnboarding)
                }
                .fullScreenCover(isPresented: $showOnboarding) {
                    OnboardingView {
                        hasSeenOnboarding = true
                        showOnboarding = false
                    }
                    .interactiveDismissDisabled()
                }
        }
        .modelContainer(container)
    }
}

/// Decides whether first-run onboarding appears.
///
/// Split out so the launch-argument overrides are in one testable place. Without
/// the automation escape hatch every UI test would have to dismiss onboarding
/// before it could reach the screen it was written to audit.
enum OnboardingGate {
    static func shouldShow(hasSeen: Bool) -> Bool {
        let args = CommandLine.arguments
        // Explicit wins, in both directions, so screenshots can force it on and
        // tests can force it off.
        if args.contains("-showOnboarding") { return true }
        if args.contains("-skipOnboarding") { return false }
        // Any deep-link or automation flag implies the test wants a specific
        // screen, not a first-run tour.
        let automationFlags = ["-uiTest", "-openResult", "-openCelebration", "-openTool",
                               "-openAssistant", "-tabCheck", "-tabToolkit", "-seedDemo",
                               "-seedBand", "-resetStore", "-forceAIStatus"]
        if args.contains(where: automationFlags.contains) { return false }
        return !hasSeen
    }
}
