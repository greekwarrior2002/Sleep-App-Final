import Foundation
import SwiftData

@Model
final class SleepSession {
    var id: UUID
    var startDate: Date
    var endDate: Date
    var totalDuration: TimeInterval
    var timeInBed: TimeInterval
    var sleepEfficiency: Double
    var deepSleepDuration: TimeInterval
    var remSleepDuration: TimeInterval
    var lightSleepDuration: TimeInterval
    var awakeDuration: TimeInterval
    var averageHeartRate: Double?
    var heartRateVariability: Double?
    var respiratoryRate: Double?
    var oxygenSaturation: Double?
    var sourceApp: String
    var sourceIdentifier: String
    @Attribute(.externalStorage) var stagesData: Data?
    var isSynced: Bool
    var createdAt: Date

    @Relationship(deleteRule: .nullify) var dailyLog: DailyLog?
    @Relationship(deleteRule: .cascade) var score: SleepScore?

    init(
        startDate: Date,
        endDate: Date,
        sourceApp: String = "Apple Health",
        sourceIdentifier: String = "",
        isSynced: Bool = true
    ) {
        self.id = UUID()
        self.startDate = startDate
        self.endDate = endDate
        self.totalDuration = 0
        self.timeInBed = endDate.timeIntervalSince(startDate)
        self.sleepEfficiency = 0
        self.deepSleepDuration = 0
        self.remSleepDuration = 0
        self.lightSleepDuration = 0
        self.awakeDuration = 0
        self.sourceApp = sourceApp
        self.sourceIdentifier = sourceIdentifier
        self.isSynced = isSynced
        self.createdAt = Date()
    }

    var stages: [SleepStageEntry] {
        get {
            guard let data = stagesData else { return [] }
            return (try? JSONDecoder().decode([SleepStageEntry].self, from: data)) ?? []
        }
        set {
            stagesData = try? JSONEncoder().encode(newValue)
        }
    }

    var durationHours: Double { totalDuration / 3600 }

    var deepSleepPercent: Double {
        guard totalDuration > 0 else { return 0 }
        return deepSleepDuration / totalDuration
    }

    var remSleepPercent: Double {
        guard totalDuration > 0 else { return 0 }
        return remSleepDuration / totalDuration
    }

    var lightSleepPercent: Double {
        guard totalDuration > 0 else { return 0 }
        return lightSleepDuration / totalDuration
    }

    var awakePercent: Double {
        guard totalDuration > 0 else { return 0 }
        return awakeDuration / totalDuration
    }

    var formattedDuration: String {
        let hours = Int(totalDuration / 3600)
        let minutes = Int((totalDuration.truncatingRemainder(dividingBy: 3600)) / 60)
        if hours == 0 { return "\(minutes)m" }
        if minutes == 0 { return "\(hours)h" }
        return "\(hours)h \(minutes)m"
    }

    var bedtimeComponents: DateComponents {
        Calendar.current.dateComponents([.hour, .minute], from: startDate)
    }

    var wakeTimeComponents: DateComponents {
        Calendar.current.dateComponents([.hour, .minute], from: endDate)
    }

    var calendarDate: Date {
        Calendar.current.startOfDay(for: endDate)
    }
}
