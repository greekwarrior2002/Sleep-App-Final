import Foundation
import SwiftData

@MainActor
final class SleepRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func save(_ session: SleepSession) throws {
        context.insert(session)
        try context.save()
    }

    func saveAll(_ sessions: [SleepSession]) throws {
        for session in sessions { context.insert(session) }
        try context.save()
    }

    func fetchAll(sortedBy keyPath: KeyPath<SleepSession, Date> = \.startDate, ascending: Bool = false) throws -> [SleepSession] {
        let descriptor = FetchDescriptor<SleepSession>(
            sortBy: [SortDescriptor(keyPath, order: ascending ? .forward : .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func fetchRecent(days: Int) throws -> [SleepSession] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let predicate = #Predicate<SleepSession> { $0.endDate >= cutoff }
        let descriptor = FetchDescriptor<SleepSession>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.endDate, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func fetchForDate(_ date: Date) throws -> SleepSession? {
        let dayStart = Calendar.current.startOfDay(for: date)
        let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart) ?? date
        let predicate = #Predicate<SleepSession> { $0.endDate >= dayStart && $0.endDate < dayEnd }
        let descriptor = FetchDescriptor<SleepSession>(predicate: predicate)
        return try context.fetch(descriptor).first
    }

    func fetchLatest() throws -> SleepSession? {
        var descriptor = FetchDescriptor<SleepSession>(
            sortBy: [SortDescriptor(\.endDate, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    func upsertFromHealthKit(_ newSessions: [SleepSession]) throws {
        let existing = try fetchAll()
        let existingIdentifiers = Set(existing.map { $0.sourceIdentifier + $0.startDate.description })

        for session in newSessions {
            let key = session.sourceIdentifier + session.startDate.description
            if !existingIdentifiers.contains(key) {
                context.insert(session)
            }
        }
        try context.save()
    }

    func delete(_ session: SleepSession) throws {
        context.delete(session)
        try context.save()
    }

    func deleteAll() throws {
        let sessions = try fetchAll()
        sessions.forEach { context.delete($0) }
        try context.save()
    }

    @discardableResult
    func deleteOlderThan(days: Int) throws -> Int {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let predicate = #Predicate<SleepSession> { $0.endDate < cutoff }
        let descriptor = FetchDescriptor<SleepSession>(predicate: predicate)
        let old = try context.fetch(descriptor)
        old.forEach { context.delete($0) }
        if !old.isEmpty { try context.save() }
        return old.count
    }
}
