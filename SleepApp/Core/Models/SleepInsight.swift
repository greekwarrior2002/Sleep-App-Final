import Foundation
import SwiftData

@Model
final class SleepInsight {
    var id: UUID
    var generatedDate: Date
    var periodStart: Date
    var periodEnd: Date
    var summary: String
    @Attribute(.externalStorage) var recommendationsData: Data?
    @Attribute(.externalStorage) var correlationsData: Data?
    var overallTrend: String
    var confidenceScore: Double
    var dataPointsAnalyzed: Int
    @Attribute(.externalStorage) var rawAPIResponse: Data?
    var isCurrentInsight: Bool
    var createdAt: Date

    init(
        periodStart: Date,
        periodEnd: Date,
        summary: String = "",
        confidenceScore: Double = 0,
        dataPointsAnalyzed: Int = 0
    ) {
        self.id = UUID()
        self.generatedDate = Date()
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.summary = summary
        self.overallTrend = "stable"
        self.confidenceScore = confidenceScore
        self.dataPointsAnalyzed = dataPointsAnalyzed
        self.isCurrentInsight = true
        self.createdAt = Date()
    }

    var recommendations: [Recommendation] {
        get { decode(recommendationsData) ?? [] }
        set { recommendationsData = encode(newValue) }
    }

    var correlations: [CorrelationFinding] {
        get { decode(correlationsData) ?? [] }
        set { correlationsData = encode(newValue) }
    }

    var trend: ScoreTrend {
        ScoreTrend(rawValue: overallTrend) ?? .stable
    }

    var confidencePercent: Int { Int(confidenceScore * 100) }

    var periodDescription: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: periodStart)) – \(formatter.string(from: periodEnd))"
    }

    private func encode<T: Encodable>(_ value: T) -> Data? {
        try? JSONEncoder().encode(value)
    }

    private func decode<T: Decodable>(_ data: Data?) -> T? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}

struct Recommendation: Codable, Identifiable {
    var id: UUID
    var title: String
    var detail: String
    var categoryRaw: String
    var priority: Int
    var isActionable: Bool

    init(title: String, detail: String, category: RecommendationCategory, priority: Int, isActionable: Bool = true) {
        self.id = UUID()
        self.title = title
        self.detail = detail
        self.categoryRaw = category.rawValue
        self.priority = priority
        self.isActionable = isActionable
    }

    var category: RecommendationCategory {
        RecommendationCategory(rawValue: categoryRaw) ?? .general
    }
}

struct CorrelationFinding: Codable, Identifiable {
    var id: UUID
    var factor: String
    var effect: String
    var directionRaw: String
    var strength: Double
    var occurrences: Int

    init(factor: String, effect: String, direction: CorrelationDirection, strength: Double, occurrences: Int) {
        self.id = UUID()
        self.factor = factor
        self.effect = effect
        self.directionRaw = direction.rawValue
        self.strength = strength
        self.occurrences = occurrences
    }

    var direction: CorrelationDirection {
        CorrelationDirection(rawValue: directionRaw) ?? .neutral
    }

    var strengthPercent: Int { Int(abs(strength) * 100) }
}
