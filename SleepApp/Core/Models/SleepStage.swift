import Foundation

enum SleepStage: String, Codable, CaseIterable, Identifiable {
    case inBed
    case lightSleep
    case deepSleep
    case remSleep
    case awake

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .inBed: return "In Bed"
        case .lightSleep: return "Light"
        case .deepSleep: return "Deep"
        case .remSleep: return "REM"
        case .awake: return "Awake"
        }
    }

    var isAsleep: Bool {
        switch self {
        case .lightSleep, .deepSleep, .remSleep: return true
        case .inBed, .awake: return false
        }
    }
}

struct SleepStageEntry: Codable, Identifiable {
    var id: UUID
    var stage: SleepStage
    var startDate: Date
    var endDate: Date

    var duration: TimeInterval { endDate.timeIntervalSince(startDate) }

    init(stage: SleepStage, startDate: Date, endDate: Date) {
        self.id = UUID()
        self.stage = stage
        self.startDate = startDate
        self.endDate = endDate
    }
}

enum ScoreTrend: String, Codable {
    case improving, stable, declining

    var icon: String {
        switch self {
        case .improving: return "arrow.up.right"
        case .stable: return "minus"
        case .declining: return "arrow.down.right"
        }
    }

    var color: String {
        switch self {
        case .improving: return "positive"
        case .stable: return "textSecondary"
        case .declining: return "scorePoor"
        }
    }
}

enum CorrelationDirection: String, Codable {
    case positive, negative, neutral
}

enum RecommendationCategory: String, Codable, CaseIterable {
    case caffeine, exercise, stress, alcohol, supplements, screenTime, schedule, environment, general

    var icon: String {
        switch self {
        case .caffeine: return "cup.and.saucer.fill"
        case .exercise: return "figure.run"
        case .stress: return "brain.head.profile"
        case .alcohol: return "wineglass.fill"
        case .supplements: return "pill.fill"
        case .screenTime: return "iphone"
        case .schedule: return "clock.fill"
        case .environment: return "bed.double.fill"
        case .general: return "sparkles"
        }
    }

    var color: String {
        switch self {
        case .caffeine: return "scoreFair"
        case .exercise: return "sleepTeal"
        case .stress: return "sleepPurpleLight"
        case .alcohol: return "scorePoor"
        case .supplements: return "positive"
        case .screenTime: return "warning"
        case .schedule: return "sleepTealLight"
        case .environment: return "stageDeep"
        case .general: return "sleepPurple"
        }
    }

    var displayName: String {
        switch self {
        case .caffeine: return "Caffeine"
        case .exercise: return "Exercise"
        case .stress: return "Stress"
        case .alcohol: return "Alcohol"
        case .supplements: return "Supplements"
        case .screenTime: return "Screen Time"
        case .schedule: return "Schedule"
        case .environment: return "Environment"
        case .general: return "General"
        }
    }
}

enum ExerciseTime: String, Codable, CaseIterable {
    case morning, afternoon, evening, night

    var displayName: String {
        switch self {
        case .morning: return "Morning"
        case .afternoon: return "Afternoon"
        case .evening: return "Evening"
        case .night: return "Night"
        }
    }

    var hoursRange: String {
        switch self {
        case .morning: return "5–11 AM"
        case .afternoon: return "11 AM–5 PM"
        case .evening: return "5–9 PM"
        case .night: return "9 PM+"
        }
    }
}
