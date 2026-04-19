import Foundation

@MainActor
final class ClaudeAIService: ObservableObject {
    static let shared = ClaudeAIService()
    private let baseURL = URL(string: "https://api.anthropic.com/v1/messages")!
    private let model = "claude-sonnet-4-6"
    private let apiVersion = "2023-06-01"

    private init() {}

    func generateInsight(
        sessions: [SleepSession],
        logs: [DailyLog],
        sleepGoalHours: Double
    ) async throws -> SleepInsight {
        guard let apiKey = KeychainService.shared.claudeAPIKey, !apiKey.isEmpty else {
            throw AIError.missingAPIKey
        }

        let recentSessions = Array(sessions.sorted { $0.startDate > $1.startDate }.prefix(30))
        let prompt = buildPrompt(sessions: recentSessions, logs: logs, sleepGoalHours: sleepGoalHours)

        let requestBody = ClaudeRequest(
            model: model,
            maxTokens: 2000,
            system: systemPrompt,
            messages: [ClaudeMessage(role: "user", content: prompt)]
        )

        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.networkError("Invalid response")
        }
        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            if httpResponse.statusCode == 401 { throw AIError.invalidAPIKey }
            throw AIError.apiError(httpResponse.statusCode, body)
        }

        return try parseResponse(data: data, sessions: recentSessions)
    }

    private var systemPrompt: String {
        """
        You are a sleep health analyst. Analyze the provided sleep and lifestyle data for a single user and generate deeply personalized insights.

        Output ONLY valid JSON — no markdown, no explanations, no text outside the JSON object.

        Return exactly this schema:
        {
          "summary": "string (2-3 sentences, reference specific numbers from the data)",
          "overallTrend": "improving|stable|declining",
          "confidenceScore": 0.0-1.0,
          "correlations": [
            {
              "factor": "string",
              "effect": "string (reference actual data numbers)",
              "direction": "positive|negative|neutral",
              "strength": -1.0 to 1.0,
              "occurrences": integer
            }
          ],
          "recommendations": [
            {
              "title": "string (concise, action-oriented)",
              "detail": "string (specific to this user's data, not generic advice)",
              "category": "caffeine|exercise|stress|alcohol|supplements|screenTime|schedule|environment|general",
              "priority": 1-5,
              "isActionable": true|false
            }
          ]
        }

        Rules:
        - Reference specific numbers: "Your deep sleep averaged 16%" not "Your deep sleep is low"
        - Minimum 5 data points before reporting a correlation
        - Recommendations must be specific to this user's patterns
        - Confidence score: <7 nights = max 0.5, 7-14 nights = max 0.75, 15+ nights = up to 1.0
        - Do not provide medical diagnoses or treatment recommendations
        - Sort recommendations by estimated impact (priority 1 = highest impact)
        - Include 2-5 correlations and 3-7 recommendations
        """
    }

    private func buildPrompt(sessions: [SleepSession], logs: [DailyLog], sleepGoalHours: Double) -> String {
        let compressedNights = sessions.map { s -> [String: Any] in
            [
                "date": ISO8601DateFormatter().string(from: s.endDate).prefix(10),
                "duration": round(s.durationHours * 10) / 10,
                "efficiency": round(s.sleepEfficiency * 1000) / 1000,
                "deepPct": round(s.deepSleepPercent * 100) / 100,
                "remPct": round(s.remSleepPercent * 100) / 100,
                "lightPct": round(s.lightSleepPercent * 100) / 100,
                "awakePct": round(s.awakePercent * 100) / 100,
                "hrv": s.heartRateVariability.map { round($0) } as Any,
                "hr": s.averageHeartRate.map { round($0) } as Any,
                "score": s.score?.overallScore as Any,
                "source": s.sourceApp
            ]
        }

        let cal = Calendar.current
        let compressedLogs = logs.map { log -> [String: Any] in
            let logDate = cal.startOfDay(for: log.date)
            return [
                "date": ISO8601DateFormatter().string(from: logDate).prefix(10),
                "caffeineMg": log.totalCaffeineMg,
                "lateCaffeine": log.hasLateCaffeine,
                "exerciseMins": log.totalExerciseMinutes,
                "eveningExercise": log.hasEveningExercise,
                "stress": log.stressLevel,
                "alcohol": log.alcoholUnits,
                "screenMins": log.screenTimeMinutes,
                "supplements": log.supplements,
                "nap": log.napDurationSeconds.map { Int($0 / 60) } as Any,
                "moodBefore": log.moodBeforeSleep,
                "moodAfter": log.moodAfterWaking
            ]
        }

        let nightsJSON = (try? JSONSerialization.data(withJSONObject: compressedNights, options: [.prettyPrinted]))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
        let logsJSON = (try? JSONSerialization.data(withJSONObject: compressedLogs, options: [.prettyPrinted]))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"

        return """
        Analyze this user's sleep and lifestyle data. Sleep goal: \(sleepGoalHours) hours/night.

        SLEEP NIGHTS (most recent first):
        \(nightsJSON)

        LIFESTYLE LOGS (day before each sleep night):
        \(logsJSON)

        Generate personalized insights based on this specific user's patterns.
        """
    }

    private func parseResponse(data: Data, sessions: [SleepSession]) throws -> SleepInsight {
        let response = try JSONDecoder().decode(ClaudeResponse.self, from: data)
        guard let content = response.content.first?.text else {
            throw AIError.parseError("No content in response")
        }

        guard let jsonData = content.data(using: .utf8),
              let parsed = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            let cleanedContent = extractJSON(from: content)
            guard let cleanData = cleanedContent.data(using: .utf8),
                  let parsedRetry = try? JSONSerialization.jsonObject(with: cleanData) as? [String: Any] else {
                throw AIError.parseError("Could not parse JSON response")
            }
            return buildInsight(from: parsedRetry, sessions: sessions, rawData: data)
        }

        return buildInsight(from: parsed, sessions: sessions, rawData: data)
    }

    private func extractJSON(from text: String) -> String {
        if let start = text.range(of: "{"),
           let end = text.range(of: "}", options: .backwards) {
            return String(text[start.lowerBound...end.upperBound])
        }
        return text
    }

    private func buildInsight(from dict: [String: Any], sessions: [SleepSession], rawData: Data) -> SleepInsight {
        let periodEnd = Date()
        let periodStart = Calendar.current.date(byAdding: .day, value: -30, to: periodEnd) ?? periodEnd

        let insight = SleepInsight(
            periodStart: periodStart,
            periodEnd: periodEnd,
            summary: dict["summary"] as? String ?? "",
            confidenceScore: dict["confidenceScore"] as? Double ?? 0.5,
            dataPointsAnalyzed: sessions.count
        )
        insight.overallTrend = dict["overallTrend"] as? String ?? "stable"
        insight.rawAPIResponse = rawData

        if let correlationsRaw = dict["correlations"] as? [[String: Any]] {
            insight.correlations = correlationsRaw.compactMap { c -> CorrelationFinding? in
                guard let factor = c["factor"] as? String,
                      let effect = c["effect"] as? String else { return nil }
                let dir = CorrelationDirection(rawValue: c["direction"] as? String ?? "") ?? .neutral
                return CorrelationFinding(
                    factor: factor,
                    effect: effect,
                    direction: dir,
                    strength: c["strength"] as? Double ?? 0,
                    occurrences: c["occurrences"] as? Int ?? 0
                )
            }
        }

        if let recsRaw = dict["recommendations"] as? [[String: Any]] {
            insight.recommendations = recsRaw.compactMap { r -> Recommendation? in
                guard let title = r["title"] as? String,
                      let detail = r["detail"] as? String else { return nil }
                let cat = RecommendationCategory(rawValue: r["category"] as? String ?? "") ?? .general
                return Recommendation(
                    title: title,
                    detail: detail,
                    category: cat,
                    priority: r["priority"] as? Int ?? 3,
                    isActionable: r["isActionable"] as? Bool ?? true
                )
            }.sorted { $0.priority < $1.priority }
        }

        return insight
    }
}

enum AIError: LocalizedError {
    case missingAPIKey
    case invalidAPIKey
    case networkError(String)
    case apiError(Int, String)
    case parseError(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: return "No API key configured. Add your Claude API key in Settings."
        case .invalidAPIKey: return "Invalid API key. Please check your key in Settings."
        case .networkError(let msg): return "Network error: \(msg)"
        case .apiError(let code, _): return "API error \(code). Please try again."
        case .parseError(let msg): return "Could not parse response: \(msg)"
        }
    }
}

private struct ClaudeRequest: Encodable {
    let model: String
    let maxTokens: Int
    let system: String
    let messages: [ClaudeMessage]

    enum CodingKeys: String, CodingKey {
        case model, system, messages
        case maxTokens = "max_tokens"
    }
}

private struct ClaudeMessage: Codable {
    let role: String
    let content: String
}

private struct ClaudeResponse: Decodable {
    let content: [ContentBlock]
    struct ContentBlock: Decodable {
        let type: String
        let text: String
    }
}
