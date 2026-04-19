import SwiftUI
import SwiftData

enum OnboardingStep: Int, CaseIterable {
    case welcome, healthKit, profile, syncing
}

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    @Published var sleepGoalHours: Double = 8.0
    @Published var bedtimeHour: Int = 22
    @Published var bedtimeMinute: Int = 30
    @Published var wakeHour: Int = 6
    @Published var wakeMinute: Int = 30
    @Published var isSyncing = false
    @Published var syncComplete = false
    @Published var syncedNightsCount = 0
    @Published var healthKitDenied = false

    @AppStorage(Constants.UserDefaults.hasCompletedOnboarding) var hasCompletedOnboarding = false
    @AppStorage(Constants.UserDefaults.sleepGoalKey) var storedGoal: Double = 8.0
    @AppStorage(Constants.UserDefaults.bedtimeHourKey) var storedBedtimeHour: Int = 22
    @AppStorage(Constants.UserDefaults.bedtimeMinuteKey) var storedBedtimeMinute: Int = 30
    @AppStorage(Constants.UserDefaults.wakeHourKey) var storedWakeHour: Int = 6
    @AppStorage(Constants.UserDefaults.wakeMinuteKey) var storedWakeMinute: Int = 30

    private let healthKit = HealthKitService.shared
    private var context: ModelContext?

    func setContext(_ context: ModelContext) {
        self.context = context
    }

    func advance() {
        withAnimation(.easeInOut(duration: 0.35)) {
            if let next = OnboardingStep(rawValue: currentStep.rawValue + 1) {
                currentStep = next
            }
        }
    }

    func requestHealthKit() async {
        do {
            let granted = try await healthKit.requestAuthorization()
            healthKitDenied = !granted
        } catch {
            healthKitDenied = true
        }
        advance()
    }

    func saveProfileAndSync() async {
        storedGoal = sleepGoalHours
        storedBedtimeHour = bedtimeHour
        storedBedtimeMinute = bedtimeMinute
        storedWakeHour = wakeHour
        storedWakeMinute = wakeMinute

        advance()
        await performSync()
    }

    private func performSync() async {
        guard let context else { return }
        isSyncing = true

        do {
            if !healthKitDenied {
                let start = Calendar.current.date(byAdding: .day, value: -60, to: Date()) ?? Date()
                let sessions = try await healthKit.fetchSleepSessions(from: start, to: Date())
                let repo = SleepRepository(context: context)
                try repo.upsertFromHealthKit(sessions)
                let scoreEngine = SleepScoreEngine()
                let allSessions = try repo.fetchAll()
                let scoreRepo = SleepScoreRepository(context: context)
                for session in allSessions where session.score == nil {
                    let recent = allSessions.filter { $0.endDate < session.endDate }.suffix(14)
                    let score = scoreEngine.calculateScore(session: session, userGoal: sleepGoalHours * 3600, recentSessions: Array(recent))
                    try scoreRepo.save(score)
                }
                syncedNightsCount = sessions.count
            }
        } catch {
            // Continue even if sync fails
        }

        isSyncing = false
        syncComplete = true
    }

    func complete() {
        hasCompletedOnboarding = true
    }
}

struct OnboardingCoordinatorView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @Environment(\.modelContext) private var context

    var body: some View {
        ZStack {
            Color.sleepBackground.ignoresSafeArea()

            switch viewModel.currentStep {
            case .welcome:
                WelcomeSplashView()
                    .environmentObject(viewModel)
                    .transition(pageTransition)
            case .healthKit:
                HealthKitPermissionView()
                    .environmentObject(viewModel)
                    .transition(pageTransition)
            case .profile:
                ProfileSetupView()
                    .environmentObject(viewModel)
                    .transition(pageTransition)
            case .syncing:
                FirstSyncView()
                    .environmentObject(viewModel)
                    .transition(pageTransition)
            }
        }
        .onAppear { viewModel.setContext(context) }
    }

    private var pageTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
}
