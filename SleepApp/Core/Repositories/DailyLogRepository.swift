import Foundation
import SwiftData

@MainActor
final class DailyLogRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func save(_ log: DailyLog) throws {
        context.insert(log)
        try context.save()
    }

    func fetchAll() throws -> [DailyLog] {
        let descriptor = FetchDescriptor<DailyLog>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func fetchForDate(_ date: Date) throws -> DailyLog? {
        let dayStart = Calendar.current.startOfDay(for: date)
        let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart) ?? date
        let predicate = #Predicate<DailyLog> { $0.date >= dayStart && $0.date < dayEnd }
        let descriptor = FetchDescriptor<DailyLog>(predicate: predicate)
        return try context.fetch(descriptor).first
    }

    func fetchOrCreate(for date: Date) throws -> DailyLog {
        if let existing = try fetchForDate(date) { return existing }
        let log = DailyLog(date: date)
        context.insert(log)
        try context.save()
        return log
    }

    func fetchRecent(days: Int) throws -> [DailyLog] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let predicate = #Predicate<DailyLog> { $0.date >= cutoff }
        let descriptor = FetchDescriptor<DailyLog>(predicate: predicate, sortBy: [SortDescriptor(\.date, order: .reverse)])
        return try context.fetch(descriptor)
    }

    func update(_ log: DailyLog) throws {
        log.updatedAt = Date()
        try context.save()
    }

    func delete(_ log: DailyLog) throws {
        context.delete(log)
        try context.save()
    }

    func deleteAll() throws {
        let logs = try fetchAll()
        logs.forEach { context.delete($0) }
        try context.save()
    }
}
