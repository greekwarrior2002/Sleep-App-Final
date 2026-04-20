import AppIntents
import SwiftUI

struct SleepScoreIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Sleep Score"
    static var description = IntentDescription("Shows last night's sleep score from Slumber.")
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some ReturnsValue<String> & ProvidesDialog {
        let defaults = UserDefaults(suiteName: "group.com.slumber.app")
        let score = defaults?.integer(forKey: "widget.lastScore") ?? 0
        let grade = defaults?.string(forKey: "widget.lastGrade") ?? "unknown"
        let duration = defaults?.string(forKey: "widget.lastDuration") ?? "unknown"

        let dialog: IntentDialog
        if score > 0 {
            dialog = IntentDialog("Your sleep score was \(score) — \(grade) — with \(duration) of sleep.")
        } else {
            dialog = IntentDialog("No sleep data found. Open Slumber and sync your health data.")
        }
        return .result(value: "\(score)", dialog: dialog)
    }
}

struct LogMoodIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Morning Mood"
    static var description = IntentDescription("Opens Slumber to log how you feel after waking up.")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        .result()
    }
}

struct SlumberShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SleepScoreIntent(),
            phrases: [
                "What was my sleep score in \(.applicationName)",
                "Check my sleep in \(.applicationName)",
                "How did I sleep in \(.applicationName)"
            ],
            shortTitle: "Sleep Score",
            systemImageName: "moon.stars.fill"
        )
        AppShortcut(
            intent: LogMoodIntent(),
            phrases: [
                "Log my mood in \(.applicationName)",
                "Morning check-in in \(.applicationName)"
            ],
            shortTitle: "Log Mood",
            systemImageName: "face.smiling"
        )
    }
}
