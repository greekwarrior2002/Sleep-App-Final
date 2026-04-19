import Foundation

enum Constants {
    enum App {
        static let name = "Slumber"
        static let bundleId = "com.slumber.app"
        static let version = "1.0.0"
    }

    enum Sleep {
        static let defaultGoalHours: Double = 8.0
        static let minimumHealthyHours: Double = 6.0
        static let maximumHealthyHours: Double = 10.0
        static let sessionGapThreshold: TimeInterval = 30 * 60
        static let minimumSessionDuration: TimeInterval = 60 * 60
    }

    enum Scoring {
        static let durationWeight = 0.25
        static let qualityWeight = 0.35
        static let consistencyWeight = 0.20
        static let recoveryWeight = 0.20

        static let idealDeepPercent = 0.20
        static let idealREMPercent = 0.25
        static let idealLightPercent = 0.45
        static let maxAwakePercent = 0.10
    }

    enum AI {
        static let insightCacheHours: Double = 24
        static let minimumNightsForInsight = 3
        static let analysisWindowDays = 30
        static let minimumCorrelationObservations = 5
    }

    enum UserDefaults {
        static let sleepGoalKey = "sleepGoalHours"
        static let bedtimeHourKey = "bedtimeHour"
        static let bedtimeMinuteKey = "bedtimeMinute"
        static let wakeHourKey = "wakeHour"
        static let wakeMinuteKey = "wakeMinute"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let bedtimeReminderEnabled = "bedtimeReminderEnabled"
        static let morningCheckinEnabled = "morningCheckinEnabled"
        static let bedtimeReminderHour = "bedtimeReminderHour"
        static let bedtimeReminderMinute = "bedtimeReminderMinute"
        static let morningCheckinHour = "morningCheckinHour"
        static let morningCheckinMinute = "morningCheckinMinute"
    }
}
