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

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .tint(ColorTokens.brandPrimary)
                .task { DemoSeed.seedIfRequested(container.mainContext) }
        }
        .modelContainer(container)
    }
}
