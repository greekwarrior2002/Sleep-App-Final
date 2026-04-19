import Foundation
import SwiftData

@Model
final class SleepScore {
    var id: UUID
    var date: Date
    var overallScore: Int
    var durationScore: Int
    var qualityScore: Int
    var consistencyScore: Int
    var recoveryScore: Int
    var trendRaw: String
    var scoringVersion: String
    var createdAt: Date

    @Relationship(deleteRule: .nullify) var session: SleepSession?

    init(date: Date = Date()) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.overallScore = 0
        self.durationScore = 0
        self.qualityScore = 0
        self.consistencyScore = 0
        self.recoveryScore = 0
        self.trendRaw = ScoreTrend.stable.rawValue
        self.scoringVersion = "1.0"
        self.createdAt = Date()
    }

    var trend: ScoreTrend {
        get { ScoreTrend(rawValue: trendRaw) ?? .stable }
        set { trendRaw = newValue.rawValue }
    }

    var grade: String {
        switch overallScore {
        case 85...: return "Excellent"
        case 70..<85: return "Good"
        case 50..<70: return "Fair"
        default: return "Poor"
        }
    }

    var gradeColor: String {
        switch overallScore {
        case 85...: return "scoreExcellent"
        case 70..<85: return "scoreGood"
        case 50..<70: return "scoreFair"
        default: return "scorePoor"
        }
    }

    var ringEndAngle: Double { Double(overallScore) / 100.0 }
}

struct UserProfile: Codable {
    var sleepGoalHours: Double
    var bedtimeHour: Int
    var bedtimeMinute: Int
    var wakeHour: Int
    var wakeMinute: Int
    var hasCompletedOnboarding: Bool

    static let `default` = UserProfile(
        sleepGoalHours: 8.0,
        bedtimeHour: 22,
        bedtimeMinute: 30,
        wakeHour: 6,
        wakeMinute: 30,
        hasCompletedOnboarding: false
    )

    var sleepGoalSeconds: TimeInterval { sleepGoalHours * 3600 }
}
