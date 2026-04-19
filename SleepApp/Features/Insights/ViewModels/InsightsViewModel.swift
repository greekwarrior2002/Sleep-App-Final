import Foundation
import SwiftData
import Combine

@MainActor
final class InsightsViewModel: ObservableObject {
    @Published var currentInsight: SleepInsight?
    @Published var pastInsights: [SleepInsight] = []
    @Published var correlations: [CorrelationFinding] = []
    @Published var isLoading = false
    @Published var isGenerating = false
    @Published var error: String?
    @Published var hasAPIKey = false

    @AppStorage(Constants.UserDefaults.sleepGoalKey) var sleepGoalHours: Double = 8.0

    private var insightRepo: InsightRepository?
    private var sleepRepo: SleepRepository?
    private var logRepo: DailyLogRepository?
    private let aiService = ClaudeAIService.shared
    private let correlationEngine = CorrelationEngine()

    func setup(context: ModelContext) {
        guard insightRepo == nil else { return }
        insightRepo = InsightRepository(context: context)
        sleepRepo = SleepRepository(context: context)
        logRepo = DailyLogRepository(context: context)
    }

    func load() async {
        guard let insightRepo, let sleepRepo, let logRepo else { return }
        isLoading = true
        defer { isLoading = false }
        hasAPIKey = KeychainService.shared.hasAPIKey
        do {
            currentInsight = try insightRepo.currentInsight()
            pastInsights = try insightRepo.fetchHistory(limit: 10)
            let sessions = try sleepRepo.fetchRecent(days: 30)
            let logs = try logRepo.fetchRecent(days: 30)
            correlations = correlationEngine.analyzeCorrelations(sessions: sessions, logs: logs)

            let shouldRegen = insightRepo.shouldRegenerate(currentSessionCount: sessions.count)
            if shouldRegen && hasAPIKey && sessions.count >= Constants.AI.minimumNightsForInsight {
                await generateInsight(sessions: sessions, logs: logs)
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func generateInsight() async {
        guard let sleepRepo, let logRepo else { return }
        do {
            let sessions = try sleepRepo.fetchRecent(days: 30)
            let logs = try logRepo.fetchRecent(days: 30)
            await generateInsight(sessions: sessions, logs: logs)
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func generateInsight(sessions: [SleepSession], logs: [DailyLog]) async {
        guard let insightRepo else { return }
        guard hasAPIKey else {
            error = "Add your Claude API key in Settings to generate insights."
            return
        }
        guard sessions.count >= Constants.AI.minimumNightsForInsight else {
            error = "Sync at least \(Constants.AI.minimumNightsForInsight) nights of sleep data to generate insights."
            return
        }

        isGenerating = true
        error = nil
        defer { isGenerating = false }

        do {
            let insight = try await aiService.generateInsight(
                sessions: sessions,
                logs: logs,
                sleepGoalHours: sleepGoalHours
            )
            try insightRepo.save(insight, sessionCount: sessions.count)
            currentInsight = insight
            pastInsights = try insightRepo.fetchHistory(limit: 10)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
