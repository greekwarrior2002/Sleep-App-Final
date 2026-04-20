import SwiftUI
import SwiftData
import BackgroundTasks

@main
struct SleepApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
                    .modelContainer(sharedModelContainer)
                    .preferredColorScheme(.dark)
                    .task { await runMaintenanceTasks() }
            } else {
                OnboardingCoordinatorView()
                    .modelContainer(sharedModelContainer)
                    .preferredColorScheme(.dark)
            }
        }
    }

    private func runMaintenanceTasks() async {
        guard hasCompletedOnboarding else { return }
        let context = sharedModelContainer.mainContext
        let repo = SleepRepository(context: context)
        try? repo.deleteOlderThan(days: 180)
        scheduleBackgroundHealthKitSync()
    }

    private func scheduleBackgroundHealthKitSync() {
        let request = BGProcessingTaskRequest(identifier: "com.slumber.healthkit.sync")
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        try? BGTaskScheduler.shared.submit(request)
    }

    let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            SleepSession.self,
            DailyLog.self,
            SleepInsight.self,
            SleepScore.self
        ])
        // Use CloudKit sync when available; fall back to local-only if iCloud is unavailable
        let cloudConfig = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
        do {
            return try ModelContainer(for: schema, configurations: [cloudConfig])
        } catch {
            // iCloud not signed in or capability missing — fall back gracefully
            let localConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            return (try? ModelContainer(for: schema, configurations: [localConfig]))
                ?? { fatalError("Could not create ModelContainer: \(error)") }()
        }
    }()
}
