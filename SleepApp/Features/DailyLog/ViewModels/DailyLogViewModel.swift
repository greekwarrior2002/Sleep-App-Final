import Foundation
import SwiftData
import Combine

@MainActor
final class DailyLogViewModel: ObservableObject {
    @Published var date: Date = Date()
    @Published var caffeineEntries: [CaffeineEntry] = []
    @Published var exerciseEntries: [ExerciseEntry] = []
    @Published var stressLevel: Int = 0
    @Published var alcoholUnits: Double = 0
    @Published var screenTimeMinutes: Int = 0
    @Published var selectedSupplements: Set<String> = []
    @Published var hasNap: Bool = false
    @Published var napDurationMinutes: Int = 20
    @Published var napTime: Date = Date()
    @Published var moodBeforeSleep: Int = 0
    @Published var moodAfterWaking: Int = 0
    @Published var notes: String = ""

    @Published var isSaving = false
    @Published var saveSuccess = false
    @Published var error: String?

    private var logRepo: DailyLogRepository?

    func setup(context: ModelContext) {
        guard logRepo == nil else { return }
        logRepo = DailyLogRepository(context: context)
    }

    func loadExisting(for date: Date = Date()) async {
        self.date = date
        guard let logRepo else { return }
        if let log = try? logRepo.fetchForDate(date) {
            caffeineEntries = log.caffeineEntries
            exerciseEntries = log.exerciseEntries
            stressLevel = log.stressLevel
            alcoholUnits = log.alcoholUnits
            screenTimeMinutes = log.screenTimeMinutes
            selectedSupplements = Set(log.supplements)
            hasNap = log.napDuration != nil
            napDurationMinutes = Int((log.napDuration ?? 1200) / 60)
            napTime = log.napTime ?? Date()
            moodBeforeSleep = log.moodBeforeSleep
            moodAfterWaking = log.moodAfterWaking
            notes = log.notes
        }
    }

    func save() async {
        guard let logRepo else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            let log = try logRepo.fetchOrCreate(for: date)
            log.caffeineEntries = caffeineEntries
            log.exerciseEntries = exerciseEntries
            log.stressLevel = stressLevel
            log.alcoholUnits = alcoholUnits
            log.screenTimeMinutes = screenTimeMinutes
            log.supplements = Array(selectedSupplements)
            log.napDuration = hasNap ? TimeInterval(napDurationMinutes * 60) : nil
            log.napTime = hasNap ? napTime : nil
            log.moodBeforeSleep = moodBeforeSleep
            log.moodAfterWaking = moodAfterWaking
            log.notes = notes
            try logRepo.update(log)
            saveSuccess = true
        } catch {
            self.error = error.localizedDescription
        }
    }

    func addCaffeineEntry(source: String) {
        let amount = CaffeineEntry.defaultAmounts[source] ?? 95
        caffeineEntries.append(CaffeineEntry(time: Date(), amountMg: amount, source: source))
    }

    func addExerciseEntry(type: String) {
        exerciseEntries.append(ExerciseEntry(type: type, durationMinutes: 30, timeOfDay: .morning))
    }

    var totalCaffeineMg: Int { caffeineEntries.reduce(0) { $0 + $1.amountMg } }
    var totalExerciseMinutes: Int { exerciseEntries.reduce(0) { $0 + $1.durationMinutes } }

    static let commonSupplements = ["Melatonin", "Magnesium", "Valerian", "Vitamin D", "Ashwagandha", "L-Theanine", "Zinc", "B12"]
}
