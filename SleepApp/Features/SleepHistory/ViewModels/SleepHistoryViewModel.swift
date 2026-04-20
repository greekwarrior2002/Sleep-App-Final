import Foundation
import SwiftData
import Combine

@MainActor
final class SleepHistoryViewModel: ObservableObject {
    enum Period: Int, CaseIterable {
        case week = 7, month = 30, quarter = 90
        var label: String {
            switch self {
            case .week: return "7 Days"
            case .month: return "30 Days"
            case .quarter: return "90 Days"
            }
        }
    }

    enum ViewMode: String, CaseIterable {
        case chart = "Chart"
        case calendar = "Calendar"
    }

    @Published var selectedPeriod: Period = .week
    @Published var selectedViewMode: ViewMode = .chart
    @Published var sessions: [SleepSession] = []
    @Published var allSessions: [SleepSession] = []
    @Published var selectedSession: SleepSession?
    @Published var isLoading = false
    @Published var sleepGoalHours: Double = Constants.Sleep.defaultGoalHours

    private var sleepRepo: SleepRepository?

    func setup(context: ModelContext) {
        guard sleepRepo == nil else { return }
        sleepRepo = SleepRepository(context: context)
    }

    func load() async {
        guard let sleepRepo else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            sessions = try sleepRepo.fetchRecent(days: selectedPeriod.rawValue)
            if allSessions.isEmpty {
                allSessions = try sleepRepo.fetchRecent(days: 365)
            }
        } catch {
            sessions = []
        }
    }

    var sessionsByDate: [Date: SleepSession] {
        var map: [Date: SleepSession] = [:]
        for session in allSessions {
            map[session.calendarDate] = session
        }
        return map
    }

    var displaySessions: [SleepSession] {
        sessions.sorted { $0.startDate < $1.startDate }
    }

    var averageDurationHours: Double {
        guard !sessions.isEmpty else { return 0 }
        return sessions.map(\.durationHours).reduce(0, +) / Double(sessions.count)
    }

    var averageScore: Int {
        let scores = sessions.compactMap { $0.score?.overallScore }
        guard !scores.isEmpty else { return 0 }
        return scores.reduce(0, +) / scores.count
    }

    var averageDeepPercent: Double {
        guard !sessions.isEmpty else { return 0 }
        return sessions.map(\.deepSleepPercent).reduce(0, +) / Double(sessions.count)
    }

    var averageEfficiency: Double {
        guard !sessions.isEmpty else { return 0 }
        return sessions.map(\.sleepEfficiency).reduce(0, +) / Double(sessions.count)
    }

    var averageHRV: Double? {
        let hrvValues = sessions.compactMap(\.heartRateVariability)
        guard !hrvValues.isEmpty else { return nil }
        return hrvValues.reduce(0, +) / Double(hrvValues.count)
    }

    var stageTotals: (deep: TimeInterval, rem: TimeInterval, light: TimeInterval) {
        let deep = sessions.map(\.deepSleepDuration).reduce(0, +)
        let rem = sessions.map(\.remSleepDuration).reduce(0, +)
        let light = sessions.map(\.lightSleepDuration).reduce(0, +)
        return (deep, rem, light)
    }
}
