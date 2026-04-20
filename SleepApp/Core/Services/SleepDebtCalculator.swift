import Foundation

struct SleepDebtResult {
    let totalDebtSeconds: TimeInterval
    let periodDays: Int
    let averageActualHours: Double
    let goalHours: Double

    var debtHours: Double { totalDebtSeconds / 3600 }
    var isInDebt: Bool { totalDebtSeconds > 0 }

    var formattedDebt: String {
        let h = Int(totalDebtSeconds / 3600)
        let m = Int((totalDebtSeconds.truncatingRemainder(dividingBy: 3600)) / 60)
        if h == 0 { return "\(m)m" }
        if m == 0 { return "\(h)h" }
        return "\(h)h \(m)m"
    }

    var debtLevel: DebtLevel {
        switch debtHours {
        case ..<1: return .none
        case 1..<3: return .mild
        case 3..<6: return .moderate
        default: return .severe
        }
    }

    enum DebtLevel {
        case none, mild, moderate, severe
    }
}

struct SleepDebtCalculator {
    func calculate(sessions: [SleepSession], goalHours: Double, days: Int = 7) -> SleepDebtResult {
        let cal = Calendar.current
        let now = Date()
        let cutoff = cal.date(byAdding: .day, value: -days, to: now) ?? now

        let recent = sessions.filter { $0.endDate >= cutoff }
        let goalSeconds = goalHours * 3600

        let totalDebt = recent.reduce(0.0) { acc, session in
            let deficit = goalSeconds - session.totalDuration
            return acc + max(0, deficit)
        }

        let avgActual = recent.isEmpty ? 0 : recent.map(\.durationHours).reduce(0, +) / Double(recent.count)

        return SleepDebtResult(
            totalDebtSeconds: totalDebt,
            periodDays: days,
            averageActualHours: avgActual,
            goalHours: goalHours
        )
    }
}
