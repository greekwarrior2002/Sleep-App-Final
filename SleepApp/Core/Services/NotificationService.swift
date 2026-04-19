import Foundation
import UserNotifications

@MainActor
final class NotificationService: ObservableObject {
    static let shared = NotificationService()
    private let center = UNUserNotificationCenter.current()

    @Published var isAuthorized = false

    private let bedtimeIdentifier = "com.slumber.bedtime-reminder"
    private let morningIdentifier = "com.slumber.morning-checkin"

    private init() {}

    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            return granted
        } catch {
            return false
        }
    }

    func scheduleBedtimeReminder(hour: Int, minute: Int) {
        center.removePendingNotificationRequests(withIdentifiers: [bedtimeIdentifier])
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Time to wind down 🌙"
        content.body = "Dim the lights, put down your phone, and start your sleep routine."
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: bedtimeIdentifier, content: content, trigger: trigger)
        center.add(request)
    }

    func scheduleMorningCheckin(hour: Int, minute: Int) {
        center.removePendingNotificationRequests(withIdentifiers: [morningIdentifier])
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Good morning ☀️"
        content.body = "How did you sleep last night? Log your night in Slumber."
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: morningIdentifier, content: content, trigger: trigger)
        center.add(request)
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }

    func checkAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }
}
