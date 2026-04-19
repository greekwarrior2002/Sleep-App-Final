import Foundation
import SwiftData

@MainActor
final class SleepScoreRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func save(_ score: SleepScore) throws {
        context.insert(score)
        try context.save()
    }

    func fetchForDate(_ date: Date) throws -> SleepScore? {
        let dayStart = Calendar.current.startOfDay(for: date)
        let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart) ?? date
        let predicate = #Predicate<SleepScore> { $0.date >= dayStart && $0.date < dayEnd }
        let descriptor = FetchDescriptor<SleepScore>(predicate: predicate)
        return try context.fetch(descriptor).first
    }

    func fetchRecent(days: Int) throws -> [SleepScore] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let predicate = #Predicate<SleepScore> { $0.date >= cutoff }
        let descriptor = FetchDescriptor<SleepScore>(predicate: predicate, sortBy: [SortDescriptor(\.date, order: .reverse)])
        return try context.fetch(descriptor)
    }

    func fetchAll() throws -> [SleepScore] {
        let descriptor = FetchDescriptor<SleepScore>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func deleteAll() throws {
        let scores = try fetchAll()
        scores.forEach { context.delete($0) }
        try context.save()
    }
}
