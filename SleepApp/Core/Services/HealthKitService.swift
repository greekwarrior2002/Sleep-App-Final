import Foundation
import HealthKit

@MainActor
final class HealthKitService: ObservableObject {
    static let shared = HealthKitService()
    private let store = HKHealthStore()

    @Published var authorizationStatus: HKAuthorizationStatus = .notDetermined
    @Published var isAvailable: Bool = HKHealthStore.isHealthDataAvailable()

    private let readTypes: Set<HKObjectType> = {
        var types = Set<HKObjectType>()
        types.insert(HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!)
        if let hr = HKObjectType.quantityType(forIdentifier: .heartRate) { types.insert(hr) }
        if let hrv = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) { types.insert(hrv) }
        if let rr = HKObjectType.quantityType(forIdentifier: .respiratoryRate) { types.insert(rr) }
        if let spo2 = HKObjectType.quantityType(forIdentifier: .oxygenSaturation) { types.insert(spo2) }
        return types
    }()

    private init() {}

    func requestAuthorization() async throws -> Bool {
        guard isAvailable else { throw HealthKitError.notAvailable }
        try await store.requestAuthorization(toShare: [], read: readTypes)
        let status = store.authorizationStatus(for: HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!)
        await MainActor.run { authorizationStatus = status }
        // HealthKit never returns .sharingAuthorized for read-only types (privacy by design).
        // Only block sync if explicitly denied; otherwise attempt the fetch.
        return status != .sharingDenied
    }

    func fetchSleepSessions(from startDate: Date, to endDate: Date) async throws -> [SleepSession] {
        let samples = try await fetchRawSleepSamples(from: startDate, to: endDate)
        let grouped = groupSamplesIntoSessions(samples)
        var sessions: [SleepSession] = []

        for group in grouped {
            guard let session = await buildSession(from: group) else { continue }
            sessions.append(session)
        }

        return sessions.sorted { $0.startDate > $1.startDate }
    }

    private func fetchRawSleepSamples(from start: Date, to end: Date) async throws -> [HKCategorySample] {
        let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: samples as? [HKCategorySample] ?? [])
                }
            }
            store.execute(query)
        }
    }

    private func groupSamplesIntoSessions(_ samples: [HKCategorySample]) -> [[HKCategorySample]] {
        let gapThreshold: TimeInterval = 30 * 60

        var bySource: [String: [HKCategorySample]] = [:]
        for sample in samples {
            let key = sample.sourceRevision.source.bundleIdentifier
            bySource[key, default: []].append(sample)
        }

        var sessions: [[HKCategorySample]] = []
        for (_, sourceSamples) in bySource {
            let sorted = sourceSamples.sorted { $0.startDate < $1.startDate }
            var currentGroup: [HKCategorySample] = []

            for sample in sorted {
                if currentGroup.isEmpty {
                    currentGroup.append(sample)
                } else if let last = currentGroup.last,
                          sample.startDate.timeIntervalSince(last.endDate) <= gapThreshold {
                    currentGroup.append(sample)
                } else {
                    if isSleepSession(currentGroup) { sessions.append(currentGroup) }
                    currentGroup = [sample]
                }
            }
            if !currentGroup.isEmpty && isSleepSession(currentGroup) {
                sessions.append(currentGroup)
            }
        }

        return sessions
    }

    private func isSleepSession(_ samples: [HKCategorySample]) -> Bool {
        let hasAsleepSample = samples.contains { sample in
            if #available(iOS 16.0, *) {
                return sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                       sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                       sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue ||
                       sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
            } else {
                return sample.value == HKCategoryValueSleepAnalysis.asleep.rawValue
            }
        }
        guard hasAsleepSample else { return false }
        let totalSpan = samples.last!.endDate.timeIntervalSince(samples.first!.startDate)
        return totalSpan >= 60 * 60
    }

    private func buildSession(from samples: [HKCategorySample]) async -> SleepSession? {
        guard let first = samples.first, let last = samples.last else { return nil }

        let source = first.sourceRevision.source
        let session = SleepSession(
            startDate: first.startDate,
            endDate: last.endDate,
            sourceApp: source.name,
            sourceIdentifier: source.bundleIdentifier
        )

        var stages: [SleepStageEntry] = []
        var deepDuration: TimeInterval = 0
        var remDuration: TimeInterval = 0
        var lightDuration: TimeInterval = 0
        var awakeDuration: TimeInterval = 0
        var asleepDuration: TimeInterval = 0

        for sample in samples {
            let dur = sample.endDate.timeIntervalSince(sample.startDate)
            let stage = mapHKSleepValue(sample.value)
            stages.append(SleepStageEntry(stage: stage, startDate: sample.startDate, endDate: sample.endDate))

            switch stage {
            case .deepSleep:
                deepDuration += dur
                asleepDuration += dur
            case .remSleep:
                remDuration += dur
                asleepDuration += dur
            case .lightSleep:
                lightDuration += dur
                asleepDuration += dur
            case .awake:
                awakeDuration += dur
            case .inBed:
                break
            }
        }

        session.stages = stages
        session.totalDuration = asleepDuration
        session.timeInBed = last.endDate.timeIntervalSince(first.startDate)
        session.deepSleepDuration = deepDuration
        session.remSleepDuration = remDuration
        session.lightSleepDuration = lightDuration
        session.awakeDuration = awakeDuration
        session.sleepEfficiency = session.timeInBed > 0 ? asleepDuration / session.timeInBed : 0

        let interval = DateInterval(start: first.startDate, end: last.endDate)
        if let hr = try? await fetchAverageHeartRate(during: interval) {
            session.averageHeartRate = hr
        }
        if let hrv = try? await fetchAverageHRV(during: interval) {
            session.heartRateVariability = hrv
        }

        return session
    }

    private func mapHKSleepValue(_ value: Int) -> SleepStage {
        if #available(iOS 16.0, *) {
            switch value {
            case HKCategoryValueSleepAnalysis.asleepDeep.rawValue: return .deepSleep
            case HKCategoryValueSleepAnalysis.asleepREM.rawValue: return .remSleep
            case HKCategoryValueSleepAnalysis.asleepCore.rawValue: return .lightSleep
            case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue: return .lightSleep
            case HKCategoryValueSleepAnalysis.awake.rawValue: return .awake
            case HKCategoryValueSleepAnalysis.inBed.rawValue: return .inBed
            default: return .inBed
            }
        } else {
            switch value {
            case HKCategoryValueSleepAnalysis.asleep.rawValue: return .lightSleep
            case HKCategoryValueSleepAnalysis.awake.rawValue: return .awake
            case HKCategoryValueSleepAnalysis.inBed.rawValue: return .inBed
            default: return .inBed
            }
        }
    }

    private func fetchAverageHeartRate(during interval: DateInterval) async throws -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: interval.start, end: interval.end)
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, stats, error in
                if let error { continuation.resume(throwing: error); return }
                let value = stats?.averageQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }

    private func fetchAverageHRV(during interval: DateInterval) async throws -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: interval.start, end: interval.end)
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, stats, error in
                if let error { continuation.resume(throwing: error); return }
                let value = stats?.averageQuantity()?.doubleValue(for: .secondUnit(with: .milli))
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }
}

enum HealthKitError: LocalizedError {
    case notAvailable
    case unauthorized
    case fetchFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAvailable: return "HealthKit is not available on this device."
        case .unauthorized: return "Slumber needs permission to access your sleep data."
        case .fetchFailed(let msg): return "Failed to fetch health data: \(msg)"
        }
    }
}
