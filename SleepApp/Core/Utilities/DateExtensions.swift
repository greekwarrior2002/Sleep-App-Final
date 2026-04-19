import Foundation

extension Date {
    var startOfDay: Date { Calendar.current.startOfDay(for: self) }

    var isToday: Bool { Calendar.current.isDateInToday(self) }
    var isYesterday: Bool { Calendar.current.isDateInYesterday(self) }

    func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: self) ?? self
    }

    var shortWeekday: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: self)
    }

    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self)
    }

    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: self)
    }

    var relativeDescription: String {
        if isToday { return "Today" }
        if isYesterday { return "Yesterday" }
        return shortDate
    }

    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }

    static func - (lhs: Date, rhs: Date) -> TimeInterval {
        lhs.timeIntervalSince(rhs)
    }
}

extension TimeInterval {
    var hoursAndMinutes: String {
        let hours = Int(self / 3600)
        let minutes = Int((self.truncatingRemainder(dividingBy: 3600)) / 60)
        if hours == 0 { return "\(minutes)m" }
        if minutes == 0 { return "\(hours)h" }
        return "\(hours)h \(minutes)m"
    }

    var hours: Double { self / 3600 }
    var minutes: Double { self / 60 }

    var hoursDecimal: String {
        String(format: "%.1f", self / 3600)
    }
}
