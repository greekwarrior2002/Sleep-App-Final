import Foundation
import SwiftData

@MainActor
final class InsightRepository {
    private let context: ModelContext
    @AppStorage("lastInsightGeneratedAt") private var lastInsightGeneratedAtDouble: Double = 0
    @AppStorage("insightSessionCount") private var insightSessionCount: Int = 0

    init(context: ModelContext) {
        self.context = context
    }

    var lastInsightGeneratedAt: Date? {
        get { lastInsightGeneratedAtDouble > 0 ? Date(timeIntervalSince1970: lastInsightGeneratedAtDouble) : nil }
        set { lastInsightGeneratedAtDouble = newValue?.timeIntervalSince1970 ?? 0 }
    }

    func currentInsight() throws -> SleepInsight? {
        let predicate = #Predicate<SleepInsight> { $0.isCurrentInsight }
        let descriptor = FetchDescriptor<SleepInsight>(predicate: predicate, sortBy: [SortDescriptor(\.generatedDate, order: .reverse)])
        return try context.fetch(descriptor).first
    }

    func shouldRegenerate(currentSessionCount: Int) -> Bool {
        guard let last = lastInsightGeneratedAt else { return true }
        let ageHours = Date().timeIntervalSince(last) / 3600
        if ageHours > 24 { return true }
        if currentSessionCount > insightSessionCount { return true }
        return false
    }

    func save(_ insight: SleepInsight, sessionCount: Int) throws {
        let existing = try fetchAll()
        for old in existing { old.isCurrentInsight = false }
        context.insert(insight)
        try context.save()
        lastInsightGeneratedAt = Date()
        insightSessionCount = sessionCount
    }

    func fetchAll() throws -> [SleepInsight] {
        let descriptor = FetchDescriptor<SleepInsight>(
            sortBy: [SortDescriptor(\.generatedDate, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func fetchHistory(limit: Int = 10) throws -> [SleepInsight] {
        var descriptor = FetchDescriptor<SleepInsight>(
            sortBy: [SortDescriptor(\.generatedDate, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try context.fetch(descriptor)
    }

    func delete(_ insight: SleepInsight) throws {
        context.delete(insight)
        try context.save()
    }

    func deleteAll() throws {
        let insights = try fetchAll()
        insights.forEach { context.delete($0) }
        lastInsightGeneratedAt = nil
        insightSessionCount = 0
        try context.save()
    }
}
