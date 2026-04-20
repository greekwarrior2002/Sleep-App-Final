import Foundation
import SwiftData
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var claudeAPIKey: String = ""
    @Published var isAPIKeyVisible = false
    @Published var showResetConfirmation = false
    @Published var successMessage: String?
    @Published var sleepGoalHours: Double = 8.0
    @Published var bedtimeHour: Int = 22
    @Published var bedtimeMinute: Int = 30
    @Published var wakeHour: Int = 6
    @Published var wakeMinute: Int = 30
    @Published var bedtimeReminderEnabled: Bool = false
    @Published var morningCheckinEnabled: Bool = false
    @Published var bedtimeReminderHour: Int = 22
    @Published var bedtimeReminderMinute: Int = 0
    @Published var morningCheckinHour: Int = 7
    @Published var morningCheckinMinute: Int = 0
    @Published var hasCompletedOnboarding: Bool = true
    @Published var appVersion: String = ""

    private let notifications = NotificationService.shared
    private var context: ModelContext?

    init() {
        claudeAPIKey = KeychainService.shared.claudeAPIKey ?? ""
        sleepGoalHours = UserDefaults.standard.double(forKey: Constants.UserDefaults.sleepGoalKey).isZero ? 8.0 : UserDefaults.standard.double(forKey: Constants.UserDefaults.sleepGoalKey)
        bedtimeHour = UserDefaults.standard.integer(forKey: Constants.UserDefaults.bedtimeHourKey).isZero ? 22 : UserDefaults.standard.integer(forKey: Constants.UserDefaults.bedtimeHourKey)
        bedtimeMinute = UserDefaults.standard.integer(forKey: Constants.UserDefaults.bedtimeMinuteKey).isZero ? 30 : UserDefaults.standard.integer(forKey: Constants.UserDefaults.bedtimeMinuteKey)
        wakeHour = UserDefaults.standard.integer(forKey: Constants.UserDefaults.wakeHourKey).isZero ? 6 : UserDefaults.standard.integer(forKey: Constants.UserDefaults.wakeHourKey)
        wakeMinute = UserDefaults.standard.integer(forKey: Constants.UserDefaults.wakeMinuteKey).isZero ? 30 : UserDefaults.standard.integer(forKey: Constants.UserDefaults.wakeMinuteKey)
        bedtimeReminderEnabled = UserDefaults.standard.bool(forKey: Constants.UserDefaults.bedtimeReminderEnabled)
        morningCheckinEnabled = UserDefaults.standard.bool(forKey: Constants.UserDefaults.morningCheckinEnabled)
        bedtimeReminderHour = UserDefaults.standard.integer(forKey: Constants.UserDefaults.bedtimeReminderHour).isZero ? 22 : UserDefaults.standard.integer(forKey: Constants.UserDefaults.bedtimeReminderHour)
        bedtimeReminderMinute = UserDefaults.standard.integer(forKey: Constants.UserDefaults.bedtimeReminderMinute)
        morningCheckinHour = UserDefaults.standard.integer(forKey: Constants.UserDefaults.morningCheckinHour).isZero ? 7 : UserDefaults.standard.integer(forKey: Constants.UserDefaults.morningCheckinHour)
        morningCheckinMinute = UserDefaults.standard.integer(forKey: Constants.UserDefaults.morningCheckinMinute)
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Constants.UserDefaults.hasCompletedOnboarding)
        appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    func setup(context: ModelContext) {
        guard self.context == nil else { return }
        self.context = context
    }

    func saveAPIKey() {
        KeychainService.shared.claudeAPIKey = claudeAPIKey.trimmingCharacters(in: .whitespaces)
        showSuccess("API key saved")
    }

    func syncToUserDefaults() {
        UserDefaults.standard.set(sleepGoalHours, forKey: Constants.UserDefaults.sleepGoalKey)
        UserDefaults.standard.set(bedtimeHour, forKey: Constants.UserDefaults.bedtimeHourKey)
        UserDefaults.standard.set(bedtimeMinute, forKey: Constants.UserDefaults.bedtimeMinuteKey)
        UserDefaults.standard.set(wakeHour, forKey: Constants.UserDefaults.wakeHourKey)
        UserDefaults.standard.set(wakeMinute, forKey: Constants.UserDefaults.wakeMinuteKey)
        UserDefaults.standard.set(bedtimeReminderEnabled, forKey: Constants.UserDefaults.bedtimeReminderEnabled)
        UserDefaults.standard.set(morningCheckinEnabled, forKey: Constants.UserDefaults.morningCheckinEnabled)
        UserDefaults.standard.set(bedtimeReminderHour, forKey: Constants.UserDefaults.bedtimeReminderHour)
        UserDefaults.standard.set(bedtimeReminderMinute, forKey: Constants.UserDefaults.bedtimeReminderMinute)
        UserDefaults.standard.set(morningCheckinHour, forKey: Constants.UserDefaults.morningCheckinHour)
        UserDefaults.standard.set(morningCheckinMinute, forKey: Constants.UserDefaults.morningCheckinMinute)
        UserDefaults.standard.set(hasCompletedOnboarding, forKey: Constants.UserDefaults.hasCompletedOnboarding)
    }

    func updateNotifications() {
        syncToUserDefaults()
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
        guard let context else { return }
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
        } catch { }
    }

    private func showSuccess(_ message: String) {
        successMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { self.successMessage = nil }
    }

    var maskedAPIKey: String {
        guard !claudeAPIKey.isEmpty else { return "" }
        return String(claudeAPIKey.prefix(8)) + String(repeating: "•", count: 20)
    }
}
