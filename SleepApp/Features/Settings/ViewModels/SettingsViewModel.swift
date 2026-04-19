import Foundation
import SwiftData
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var claudeAPIKey: String = ""
    @Published var isAPIKeyVisible = false
    @Published var showResetConfirmation = false
    @Published var isSaving = false
    @Published var successMessage: String?

    @AppStorage(Constants.UserDefaults.sleepGoalKey) var sleepGoalHours: Double = 8.0
    @AppStorage(Constants.UserDefaults.bedtimeHourKey) var bedtimeHour: Int = 22
    @AppStorage(Constants.UserDefaults.bedtimeMinuteKey) var bedtimeMinute: Int = 30
    @AppStorage(Constants.UserDefaults.wakeHourKey) var wakeHour: Int = 6
    @AppStorage(Constants.UserDefaults.wakeMinuteKey) var wakeMinute: Int = 30
    @AppStorage(Constants.UserDefaults.bedtimeReminderEnabled) var bedtimeReminderEnabled: Bool = false
    @AppStorage(Constants.UserDefaults.morningCheckinEnabled) var morningCheckinEnabled: Bool = false
    @AppStorage(Constants.UserDefaults.bedtimeReminderHour) var bedtimeReminderHour: Int = 22
    @AppStorage(Constants.UserDefaults.bedtimeReminderMinute) var bedtimeReminderMinute: Int = 0
    @AppStorage(Constants.UserDefaults.morningCheckinHour) var morningCheckinHour: Int = 7
    @AppStorage(Constants.UserDefaults.morningCheckinMinute) var morningCheckinMinute: Int = 0
    @AppStorage(Constants.UserDefaults.hasCompletedOnboarding) var hasCompletedOnboarding: Bool = true

    private let notifications = NotificationService.shared
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
        self.claudeAPIKey = KeychainService.shared.claudeAPIKey ?? ""
    }

    func saveAPIKey() {
        KeychainService.shared.claudeAPIKey = claudeAPIKey.trimmingCharacters(in: .whitespaces)
        showSuccess("API key saved")
    }

    func updateNotifications() {
        Task {
            if bedtimeReminderEnabled {
                let authorized = await notifications.requestPermission()
                if authorized {
                    notifications.scheduleBedtimeReminder(hour: bedtimeReminderHour, minute: bedtimeReminderMinute)
                } else {
                    bedtimeReminderEnabled = false
                }
            } else {
                notifications.cancelAll()
            }

            if morningCheckinEnabled {
                notifications.scheduleMorningCheckin(hour: morningCheckinHour, minute: morningCheckinMinute)
            }
        }
    }

    func resetAllData() async {
        do {
            let sleepRepo = SleepRepository(context: context)
            let logRepo = DailyLogRepository(context: context)
            let insightRepo = InsightRepository(context: context)
            let scoreRepo = SleepScoreRepository(context: context)

            try sleepRepo.deleteAll()
            try logRepo.deleteAll()
            try insightRepo.deleteAll()
            try scoreRepo.deleteAll()

            KeychainService.shared.claudeAPIKey = nil
            claudeAPIKey = ""
            hasCompletedOnboarding = false
        } catch {
            // Handle silently
        }
    }

    private func showSuccess(_ message: String) {
        successMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.successMessage = nil
        }
    }

    var maskedAPIKey: String {
        guard !claudeAPIKey.isEmpty else { return "" }
        let prefix = String(claudeAPIKey.prefix(8))
        return prefix + String(repeating: "•", count: 20)
    }

    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}
