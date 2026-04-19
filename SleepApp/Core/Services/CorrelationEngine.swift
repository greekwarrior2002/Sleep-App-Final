import Foundation

struct CorrelationEngine {

    private let minimumObservations = 5

    func analyzeCorrelations(sessions: [SleepSession], logs: [DailyLog]) -> [CorrelationFinding] {
        let pairs = matchSessionsWithLogs(sessions: sessions, logs: logs)
        guard pairs.count >= minimumObservations else { return [] }

        var findings: [CorrelationFinding] = []

        if let f = lateCaffeineCorrelation(pairs: pairs) { findings.append(f) }
        if let f = alcoholREMCorrelation(pairs: pairs) { findings.append(f) }
        if let f = eveningExerciseCorrelation(pairs: pairs) { findings.append(f) }
        if let f = stressEfficiencyCorrelation(pairs: pairs) { findings.append(f) }
        if let f = screenTimeCorrelation(pairs: pairs) { findings.append(f) }
        if let f = totalCaffeineCorrelation(pairs: pairs) { findings.append(f) }

        return findings
            .filter { abs($0.strength) > 0.2 }
            .sorted { abs($0.strength) > abs($1.strength) }
    }

    private func matchSessionsWithLogs(sessions: [SleepSession], logs: [DailyLog]) -> [(SleepSession, DailyLog)] {
        let cal = Calendar.current
        return sessions.compactMap { session in
            let sessionDate = cal.startOfDay(for: session.endDate)
            let previousDay = cal.date(byAdding: .day, value: -1, to: sessionDate)!
            if let log = logs.first(where: { cal.isDate($0.date, inSameDayAs: previousDay) }) {
                return (session, log)
            }
            return nil
        }
    }

    private func lateCaffeineCorrelation(pairs: [(SleepSession, DailyLog)]) -> CorrelationFinding? {
        let withLate = pairs.filter { $0.1.hasLateCaffeine }
        let withoutLate = pairs.filter { !$0.1.hasLateCaffeine }

        guard withLate.count >= minimumObservations, withoutLate.count >= minimumObservations else { return nil }

        let deepWithLate = withLate.map { $0.0.deepSleepPercent }.average
        let deepWithout = withoutLate.map { $0.0.deepSleepPercent }.average
        let diff = deepWithLate - deepWithout
        guard abs(diff) > 0.03 else { return nil }

        let direction: CorrelationDirection = diff < 0 ? .negative : .positive
        let strength = min(abs(diff) * 5, 1.0) * (direction == .negative ? -1 : 1)
        let pct = Int(abs(diff) * 100)
        let dir = diff < 0 ? "reduced" : "increased"

        return CorrelationFinding(
            factor: "Caffeine after 2 PM",
            effect: "Deep sleep \(dir) by ~\(pct)% on nights after late caffeine",
            direction: direction,
            strength: strength,
            occurrences: withLate.count
        )
    }

    private func alcoholREMCorrelation(pairs: [(SleepSession, DailyLog)]) -> CorrelationFinding? {
        let withAlcohol = pairs.filter { $0.1.alcoholUnits >= 1 }
        let withoutAlcohol = pairs.filter { $0.1.alcoholUnits < 0.5 }

        guard withAlcohol.count >= minimumObservations, withoutAlcohol.count >= minimumObservations else { return nil }

        let remWith = withAlcohol.map { $0.0.remSleepPercent }.average
        let remWithout = withoutAlcohol.map { $0.0.remSleepPercent }.average
        let diff = remWith - remWithout
        guard abs(diff) > 0.03 else { return nil }

        let direction: CorrelationDirection = diff < 0 ? .negative : .positive
        let strength = min(abs(diff) * 5, 1.0) * (direction == .negative ? -1 : 1)
        let pct = Int(abs(diff) * 100)
        let dir = diff < 0 ? "reduced" : "increased"

        return CorrelationFinding(
            factor: "Alcohol consumption",
            effect: "REM sleep \(dir) by ~\(pct)% on nights after drinking",
            direction: direction,
            strength: strength,
            occurrences: withAlcohol.count
        )
    }

    private func eveningExerciseCorrelation(pairs: [(SleepSession, DailyLog)]) -> CorrelationFinding? {
        let eveningEx = pairs.filter { $0.1.hasEveningExercise }
        let noEveningEx = pairs.filter { !$0.1.hasEveningExercise && !$0.1.exerciseEntries.isEmpty }

        guard eveningEx.count >= minimumObservations, noEveningEx.count >= minimumObservations else { return nil }

        let deepEvening = eveningEx.map { $0.0.deepSleepPercent }.average
        let deepMorning = noEveningEx.map { $0.0.deepSleepPercent }.average
        let diff = deepEvening - deepMorning
        guard abs(diff) > 0.02 else { return nil }

        let direction: CorrelationDirection = diff > 0 ? .positive : .negative
        let strength = min(abs(diff) * 5, 1.0) * (direction == .positive ? 1 : -1)
        let pct = Int(abs(diff) * 100)
        let dir = diff > 0 ? "higher" : "lower"

        return CorrelationFinding(
            factor: "Evening exercise",
            effect: "Deep sleep is \(dir) by ~\(pct)% compared to morning workouts",
            direction: direction,
            strength: strength,
            occurrences: eveningEx.count
        )
    }

    private func stressEfficiencyCorrelation(pairs: [(SleepSession, DailyLog)]) -> CorrelationFinding? {
        let filtered = pairs.filter { $0.1.stressLevel > 0 }
        guard filtered.count >= minimumObservations else { return nil }

        let stress = filtered.map { Double($0.1.stressLevel) }
        let efficiency = filtered.map { $0.0.sleepEfficiency * 100 }
        let r = pearsonCorrelation(stress, efficiency)
        guard abs(r) > 0.25 else { return nil }

        let direction: CorrelationDirection = r < 0 ? .negative : .positive
        let dir = r < 0 ? "decreases" : "increases"

        return CorrelationFinding(
            factor: "Stress level",
            effect: "Sleep efficiency \(dir) as stress goes up (r = \(String(format: "%.2f", r)))",
            direction: direction,
            strength: r,
            occurrences: filtered.count
        )
    }

    private func screenTimeCorrelation(pairs: [(SleepSession, DailyLog)]) -> CorrelationFinding? {
        let filtered = pairs.filter { $0.1.screenTimeMinutes > 0 }
        guard filtered.count >= minimumObservations else { return nil }

        let highScreen = pairs.filter { $0.1.screenTimeMinutes >= 60 }
        let lowScreen = pairs.filter { $0.1.screenTimeMinutes < 30 }
        guard highScreen.count >= minimumObservations, lowScreen.count >= minimumObservations else { return nil }

        let effHigh = highScreen.map { $0.0.sleepEfficiency }.average
        let effLow = lowScreen.map { $0.0.sleepEfficiency }.average
        let diff = effHigh - effLow
        guard abs(diff) > 0.02 else { return nil }

        let direction: CorrelationDirection = diff < 0 ? .negative : .positive
        let strength = min(abs(diff) * 8, 1.0) * (direction == .negative ? -1 : 1)
        let pct = Int(abs(diff) * 100)
        let dir = diff < 0 ? "lower" : "higher"

        return CorrelationFinding(
            factor: "Screen time before bed",
            effect: "Sleep efficiency is \(pct)% \(dir) on heavy screen nights",
            direction: direction,
            strength: strength,
            occurrences: highScreen.count
        )
    }

    private func totalCaffeineCorrelation(pairs: [(SleepSession, DailyLog)]) -> CorrelationFinding? {
        let filtered = pairs.filter { $0.1.totalCaffeineMg > 0 }
        guard filtered.count >= minimumObservations else { return nil }

        let caffeine = filtered.map { Double($0.1.totalCaffeineMg) }
        let duration = filtered.map { $0.0.totalDuration / 3600 }
        let r = pearsonCorrelation(caffeine, duration)
        guard abs(r) > 0.25 else { return nil }

        let direction: CorrelationDirection = r < 0 ? .negative : .positive
        let dir = r < 0 ? "decreases" : "increases"

        return CorrelationFinding(
            factor: "Total caffeine intake",
            effect: "Sleep duration \(dir) on high-caffeine days",
            direction: direction,
            strength: r,
            occurrences: filtered.count
        )
    }

    func pearsonCorrelation(_ x: [Double], _ y: [Double]) -> Double {
        guard x.count == y.count, x.count > 1 else { return 0 }
        let n = Double(x.count)
        let meanX = x.reduce(0, +) / n
        let meanY = y.reduce(0, +) / n
        let numerator = zip(x, y).reduce(0.0) { $0 + ($1.0 - meanX) * ($1.1 - meanY) }
        let dX = sqrt(x.reduce(0.0) { $0 + pow($1 - meanX, 2) })
        let dY = sqrt(y.reduce(0.0) { $0 + pow($1 - meanY, 2) })
        guard dX > 0, dY > 0 else { return 0 }
        return numerator / (dX * dY)
    }
}

private extension Array where Element == Double {
    var average: Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }
}
