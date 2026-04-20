import Foundation

struct BedtimeWindow {
    let bedtime: Date
    let cycleCount: Int
    let estimatedDuration: TimeInterval

    var formattedBedtime: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "h:mm a"
        return fmt.string(from: bedtime)
    }

    var formattedDuration: String {
        let h = Int(estimatedDuration / 3600)
        let m = Int((estimatedDuration.truncatingRemainder(dividingBy: 3600)) / 60)
        if m == 0 { return "\(h)h" }
        return "\(h)h \(m)m"
    }
}

struct BedtimeOptimizer {
    // Average time to fall asleep
    private let sleepOnsetLatency: TimeInterval = 14 * 60

    func recommendedBedtimes(wakeHour: Int, wakeMinute: Int, sessions: [SleepSession]) -> [BedtimeWindow] {
        let cycleDuration = averageCycleDuration(from: sessions)
        let cal = Calendar.current
        var wakeComponents = cal.dateComponents([.year, .month, .day], from: Date())
        wakeComponents.hour = wakeHour
        wakeComponents.minute = wakeMinute
        wakeComponents.second = 0

        // If wake time has already passed today, use tomorrow's date
        var wakeDate = cal.date(from: wakeComponents) ?? Date()
        if wakeDate < Date() {
            wakeDate = cal.date(byAdding: .day, value: 1, to: wakeDate) ?? wakeDate
        }

        // Offer 4, 5, and 6 full sleep cycles
        return [6, 5, 4].compactMap { cycles -> BedtimeWindow? in
            let sleepDuration = Double(cycles) * cycleDuration
            let bedtime = wakeDate.addingTimeInterval(-(sleepDuration + sleepOnsetLatency))
            guard bedtime > Date() else { return nil }
            return BedtimeWindow(bedtime: bedtime, cycleCount: cycles, estimatedDuration: sleepDuration)
        }
    }

    private func averageCycleDuration(from sessions: [SleepSession]) -> TimeInterval {
        let defaultCycle: TimeInterval = 90 * 60
        guard sessions.count >= 5 else { return defaultCycle }

        // Estimate average full cycle from sessions with stage data
        let validSessions = sessions.filter { $0.totalDuration > 0 && ($0.deepSleepDuration + $0.remSleepDuration) > 0 }
        guard validSessions.count >= 3 else { return defaultCycle }

        let avgDuration = validSessions.map(\.totalDuration).reduce(0, +) / Double(validSessions.count)
        // Round to nearest 15-minute increment for cycle estimate
        let estimatedCycles = max(4.0, round(avgDuration / defaultCycle))
        return (avgDuration / estimatedCycles).clamped(to: (75 * 60)...(105 * 60))
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
