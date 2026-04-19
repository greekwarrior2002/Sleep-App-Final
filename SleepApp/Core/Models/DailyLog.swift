import Foundation
import SwiftData

@Model
final class DailyLog {
    var id: UUID
    var date: Date
    @Attribute(.externalStorage) var caffeineData: Data?
    @Attribute(.externalStorage) var exerciseData: Data?
    var stressLevel: Int
    var alcoholUnits: Double
    var screenTimeMinutes: Int
    @Attribute(.externalStorage) var supplementsData: Data?
    var napDurationSeconds: Double?
    var napTime: Date?
    var moodBeforeSleep: Int
    var moodAfterWaking: Int
    var notes: String
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .nullify) var sleepSession: SleepSession?

    init(date: Date = Date()) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.stressLevel = 0
        self.alcoholUnits = 0
        self.screenTimeMinutes = 0
        self.moodBeforeSleep = 0
        self.moodAfterWaking = 0
        self.notes = ""
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var caffeineEntries: [CaffeineEntry] {
        get { decode(caffeineData) ?? [] }
        set { caffeineData = encode(newValue) }
    }

    var exerciseEntries: [ExerciseEntry] {
        get { decode(exerciseData) ?? [] }
        set { exerciseData = encode(newValue) }
    }

    var supplements: [String] {
        get { decode(supplementsData) ?? [] }
        set { supplementsData = encode(newValue) }
    }

    var napDuration: TimeInterval? {
        get { napDurationSeconds.map { TimeInterval($0) } }
        set { napDurationSeconds = newValue.map { Double($0) } }
    }

    var totalCaffeineMg: Int { caffeineEntries.reduce(0) { $0 + $1.amountMg } }

    var hasLateCaffeine: Bool {
        let cutoffHour = 14
        return caffeineEntries.contains { entry in
            Calendar.current.component(.hour, from: entry.time) >= cutoffHour
        }
    }

    var totalExerciseMinutes: Int { exerciseEntries.reduce(0) { $0 + $1.durationMinutes } }

    var hasEveningExercise: Bool {
        exerciseEntries.contains { $0.timeOfDay == .evening || $0.timeOfDay == .night }
    }

    private func encode<T: Encodable>(_ value: T) -> Data? {
        try? JSONEncoder().encode(value)
    }

    private func decode<T: Decodable>(_ data: Data?) -> T? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}

struct CaffeineEntry: Codable, Identifiable {
    var id: UUID
    var time: Date
    var amountMg: Int
    var source: String

    init(time: Date = Date(), amountMg: Int, source: String) {
        self.id = UUID()
        self.time = time
        self.amountMg = amountMg
        self.source = source
    }

    static let commonSources = ["Coffee", "Espresso", "Tea", "Green Tea", "Energy Drink", "Soda", "Pre-Workout"]
    static let defaultAmounts: [String: Int] = [
        "Coffee": 95,
        "Espresso": 63,
        "Tea": 47,
        "Green Tea": 28,
        "Energy Drink": 160,
        "Soda": 35,
        "Pre-Workout": 200
    ]
}

struct ExerciseEntry: Codable, Identifiable {
    var id: UUID
    var type: String
    var durationMinutes: Int
    var timeOfDay: ExerciseTime
    var intensityLevel: Int

    init(type: String, durationMinutes: Int, timeOfDay: ExerciseTime, intensityLevel: Int = 2) {
        self.id = UUID()
        self.type = type
        self.durationMinutes = durationMinutes
        self.timeOfDay = timeOfDay
        self.intensityLevel = intensityLevel
    }

    static let commonTypes = ["Running", "Walking", "Cycling", "Strength", "HIIT", "Yoga", "Swimming", "Other"]
}
