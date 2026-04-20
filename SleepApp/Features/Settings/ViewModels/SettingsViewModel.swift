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
        let defaults = UserDefaults.standard
        claudeAPIKey = KeychainService.shared.claudeAPIKey ?? ""
        let goal = defaults.double(forKey: Constants.UserDefaults.sleepGoalKey)
        sleepGoalHours = goal == 0 ? 8.0 : goal
        let bh = defaults.integer(forKey: Constants.UserDefaults.bedtimeHourKey)
        bedtimeHour = bh == 0 ? 22 : bh
        let bm = defaults.integer(forKey: Constants.UserDefaults.bedtimeMinuteKey)
        bedtimeMinute = bm == 0 ? 30 : bm
        let wh = defaults.integer(forKey: Constants.UserDefaults.wakeHourKey)
        wakeHour = wh == 0 ? 6 : wh
        let wm = defaults.integer(forKey: Constants.UserDefaults.wakeMinuteKey)
        wakeMinute = wm == 0 ? 30 : wm
        bedtimeReminderEnabled = defaults.bool(forKey: Constants.UserDefaults.bedtimeReminderEnabled)
        morningCheckinEnabled = defaults.bool(forKey: Constants.UserDefaults.morningCheckinEnabled)
        let brh = defaults.integer(forKey: Constants.UserDefaults.bedtimeReminderHour)
        bedtimeReminderHour = brh == 0 ? 22 : brh
        bedtimeReminderMinute = defaults.integer(forKey: Constants.UserDefaults.bedtimeReminderMinute)
        let mch = defaults.integer(forKey: Constants.UserDefaults.morningCheckinHour)
        morningCheckinHour = mch == 0 ? 7 : mch
        morningCheckinMinute = defaults.integer(forKey: Constants.UserDefaults.morningCheckinMinute)
        hasCompletedOnboarding = defaults.bool(forKey: Constants.UserDefaults.hasCompletedOnboarding)
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
