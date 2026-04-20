import Foundation
import SwiftData
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var lastNightSession: SleepSession?
    @Published var lastNightScore: SleepScore?
    @Published var recentSessions: [SleepSession] = []
    @Published var currentInsight: SleepInsight?
    @Published var isLoading = false
    @Published var isSyncing = false
    @Published var error: String?
    @Published var hasCheckedInToday = false
    @Published var todayLog: DailyLog?
    @Published var sleepGoalHours: Double = Constants.Sleep.defaultGoalHours

    private var sleepRepo: SleepRepository?
    private var scoreRepo: SleepScoreRepository?
    private var insightRepo: InsightRepository?
    private var logRepo: DailyLogRepository?
    private let healthKit = HealthKitService.shared
    private let scoreEngine = SleepScoreEngine()

    func setup(context: ModelContext) {
        guard sleepRepo == nil else { return }
        sleepRepo = SleepRepository(context: context)
        scoreRepo = SleepScoreRepository(context: context)
        insightRepo = InsightRepository(context: context)
        logRepo = DailyLogRepository(context: context)
    }

    func load() async {
        guard let sleepRepo, let scoreRepo, let insightRepo, let logRepo else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            recentSessions = try sleepRepo.fetchRecent(days: 30)
            lastNightSession = recentSessions.first
            lastNightScore = lastNightSession.flatMap { try? scoreRepo.fetchForDate($0.calendarDate) }
            currentInsight = try insightRepo.currentInsight()
            todayLog = try logRepo.fetchForDate(Date())
            hasCheckedInToday = todayLog?.moodAfterWaking ?? 0 > 0
        } catch {
            self.error = error.localizedDescription
        }
    }

    func syncHealthKit() async {
        guard let sleepRepo, let scoreRepo else { return }
        isSyncing = true
        defer { isSyncing = false }
        do {
            let authorized = try await healthKit.requestAuthorization()
            guard authorized else { return }

            let start = Calendar.current.date(byAdding: .day, value: -60, to: Date()) ?? Date()
            let sessions = try await healthKit.fetchSleepSessions(from: start, to: Date())
            try sleepRepo.upsertFromHealthKit(sessions)

            let allSessions = try sleepRepo.fetchAll()
            for session in allSessions where session.score == nil {
                let recent = allSessions.filter { $0.endDate < session.endDate }.suffix(14)
                let score = scoreEngine.calculateScore(
                    session: session,
                    userGoal: sleepGoalHours * 3600,
                    recentSessions: Array(recent)
                )
                score.session = session
                try scoreRepo.save(score)
            }
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func saveCheckin(mood: Int) async {
        guard let logRepo else { return }
        do {
            let log = try logRepo.fetchOrCreate(for: Date())
            log.moodAfterWaking = mood
            try logRepo.update(log)
            todayLog = log
            hasCheckedInToday = true
        } catch {
            self.error = error.localizedDescription
        }
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Good night"
        }
    }

    var weeklyAvgScore: Int {
        let scores = recentSessions.prefix(7).compactMap { $0.score?.overallScore }
        guard !scores.isEmpty else { return 0 }
        return scores.reduce(0, +) / scores.count
    }

    var last7Sessions: [SleepSession] {
        Array(recentSessions.prefix(7).reversed())
    }
}
