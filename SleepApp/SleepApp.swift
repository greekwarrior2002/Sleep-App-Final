import SwiftUI
import SwiftData

@main
struct SleepApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
                    .modelContainer(sharedModelContainer)
                    .preferredColorScheme(.dark)
            } else {
                OnboardingCoordinatorView()
                    .modelContainer(sharedModelContainer)
                    .preferredColorScheme(.dark)
            }
        }
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            SleepSession.self,
            DailyLog.self,
            SleepInsight.self,
            SleepScore.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}
