import Foundation

struct SleepScoreEngine {

    func calculateScore(
        session: SleepSession,
        userGoal: TimeInterval,
        recentSessions: [SleepSession]
    ) -> SleepScore {
        let score = SleepScore(date: session.calendarDate)

        let dScore = durationScore(actual: session.totalDuration, goal: userGoal)
        let qScore = qualityScore(session: session)
        let cScore = consistencyScore(
            bedtime: session.startDate,
            recentBedtimes: recentSessions.map(\.startDate)
        )
        let rScore = recoveryScore(session: session, recentSessions: recentSessions)

        let overall = Int(
            Double(dScore) * 0.25 +
            Double(qScore) * 0.35 +
            Double(cScore) * 0.20 +
            Double(rScore) * 0.20
        )

        score.durationScore = dScore
        score.qualityScore = qScore
        score.consistencyScore = cScore
        score.recoveryScore = rScore
        score.overallScore = min(100, max(0, overall))
        score.trend = calculateTrend(currentScore: overall, recentSessions: recentSessions)
        score.session = session

        return score
    }

    private func durationScore(actual: TimeInterval, goal: TimeInterval) -> Int {
        guard actual > 0 else { return 0 }
        let ratio = actual / goal

        if actual < 6 * 3600 {
            return Int(min(ratio, 1.0) * 50)
        }
        if ratio >= 1.0 {
            return min(100, Int(90 + (ratio - 1.0) * 20))
        }
        return Int(ratio * 90)
    }

    private func qualityScore(session: SleepSession) -> Int {
        guard session.totalDuration > 0 else { return 0 }

        let idealDeep = 0.20
        let idealREM = 0.25
        let idealLight = 0.45
        let maxAwake = 0.10

        var score = 100.0

        let deepDev = abs(session.deepSleepPercent - idealDeep)
        score -= deepDev * 100

        let remDev = abs(session.remSleepPercent - idealREM)
        score -= remDev * 80

        let lightDev = max(0, session.lightSleepPercent - (idealLight + 0.1))
        score -= lightDev * 60

        let excessAwake = max(0, session.awakePercent - maxAwake)
        score -= excessAwake * 150

        if let hrv = session.heartRateVariability, hrv > 40 {
            score += 5
        }

        return min(100, max(0, Int(score)))
    }

    private func consistencyScore(bedtime: Date, recentBedtimes: [Date]) -> Int {
        guard !recentBedtimes.isEmpty else { return 70 }

        let cal = Calendar.current
        let bedtimeMinutes = cal.component(.hour, from: bedtime) * 60 + cal.component(.minute, from: bedtime)

        let recentMinutes = recentBedtimes.suffix(14).map { bt -> Int in
            let h = cal.component(.hour, from: bt)
            let m = cal.component(.minute, from: bt)
            return h * 60 + m
        }

        var adjustedMinutes = recentMinutes.map { m -> Int in
            var diff = m - bedtimeMinutes
            if diff > 720 { diff -= 1440 }
            if diff < -720 { diff += 1440 }
            return diff
        }
        adjustedMinutes.sort()

        let median: Int
        let count = adjustedMinutes.count
        if count % 2 == 0 {
            median = (adjustedMinutes[count/2 - 1] + adjustedMinutes[count/2]) / 2
        } else {
            median = adjustedMinutes[count/2]
        }

        let deviation = abs(median)
        switch deviation {
        case 0..<15: return 100
        case 15..<30: return 80
        case 30..<60: return 55
        case 60..<90: return 35
        default: return 15
        }
    }

    private func recoveryScore(session: SleepSession, recentSessions: [SleepSession]) -> Int {
        var score = session.sleepEfficiency * 100

        if let hrv = session.heartRateVariability {
            let recentHRVs = recentSessions.suffix(7).compactMap(\.heartRateVariability)
            if !recentHRVs.isEmpty {
                let avgHRV = recentHRVs.reduce(0, +) / Double(recentHRVs.count)
                if avgHRV > 0 {
                    let ratio = hrv / avgHRV
                    if ratio > 1.1 { score += 10 }
                    else if ratio < 0.9 { score -= 10 }
                }
            }
        }

        return min(100, max(0, Int(score)))
    }

    private func calculateTrend(currentScore: Int, recentSessions: [SleepSession]) -> ScoreTrend {
        guard recentSessions.count >= 3 else { return .stable }
        let recentScores = recentSessions.suffix(7).compactMap { $0.score?.overallScore }
        guard recentScores.count >= 3 else { return .stable }
        let avg = recentScores.reduce(0, +) / recentScores.count
        if currentScore > avg + 5 { return .improving }
        if currentScore < avg - 5 { return .declining }
        return .stable
    }

    func batchCalculate(sessions: [SleepSession], userGoal: TimeInterval) -> [SleepScore] {
        sessions.enumerated().map { index, session in
            let recent = Array(sessions[max(0, index - 14)..<index])
            return calculateScore(session: session, userGoal: userGoal, recentSessions: recent)
        }
    }
}
