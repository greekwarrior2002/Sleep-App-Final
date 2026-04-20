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
    @Published var error: String?

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
            try await healthKit.requestAuthorization()
            healthKitDenied = false
            error = nil
        } catch {
            healthKitDenied = true
            self.error = error.localizedDescription
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
        error = nil

        do {
            if !healthKitDenied {
                let calendar = Calendar.current
                // Keep onboarding responsive: import a smaller recent window first.
                let ninetyDaysAgo = calendar.date(byAdding: .day, value: -90, to: Date()) ?? Date()
                let start = calendar.startOfDay(for: ninetyDaysAgo)
                let sessions = try await healthKit.fetchSleepSessions(from: start, to: Date())
                guard !sessions.isEmpty else {
                    self.error = "HealthKit returned no sleep sessions for the last 90 days."
                    syncComplete = true
                    isSyncing = false
                    return
                }
                let repo = SleepRepository(context: context)
                try repo.upsertFromHealthKit(sessions)
                let scoreEngine = SleepScoreEngine()
                let allSessions = try repo.fetchAll().sorted { $0.endDate < $1.endDate }
                let scoreRepo = SleepScoreRepository(context: context)
                // Score only recent sessions during onboarding for faster completion.
                let sessionsToScore = Array(allSessions.suffix(30))
                for (idx, session) in sessionsToScore.enumerated() where session.score == nil {
                    let recent = Array(sessionsToScore.prefix(idx).suffix(14))
                    let score = scoreEngine.calculateScore(
                        session: session,
                        userGoal: sleepGoalHours * 3600,
                        recentSessions: recent
                    )
                    score.session = session
                    try scoreRepo.save(score)
                }
                syncedNightsCount = sessions.count
            }
        } catch {
            self.error = error.localizedDescription
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
