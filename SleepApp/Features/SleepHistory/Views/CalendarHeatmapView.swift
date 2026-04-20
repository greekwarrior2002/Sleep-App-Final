import SwiftUI

struct CalendarHeatmapView: View {
    let sessionsByDate: [Date: SleepSession]
    let onSelectSession: (SleepSession) -> Void

    @State private var displayedMonth: Date = Calendar.current.startOfMonth(for: Date())

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekdayLabels = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                monthHeader
                Divider().overlay(Color.sleepBorder)
                weekdayRow
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(leadingEmptyCells, id: \.self) { _ in Color.clear.aspectRatio(1, contentMode: .fit) }
                    ForEach(daysInMonth, id: \.self) { date in
                        CalendarDayCell(
                            date: date,
                            session: sessionsByDate[date],
                            onTap: { if let s = sessionsByDate[date] { onSelectSession(s) } }
                        )
                    }
                }
                legend
            }
        }
    }

    private var monthHeader: some View {
        HStack {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    displayedMonth = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.sleepPurpleLight)
            }
            .buttonStyle(.plain)
            Spacer()
            Text(displayedMonth.monthYearString)
                .font(.titleSmall).fontWeight(.semibold).foregroundStyle(.textPrimary)
            Spacer()
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    let next = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                    if next <= Calendar.current.startOfMonth(for: Date()) { displayedMonth = next }
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(canGoForward ? .sleepPurpleLight : Color.textTertiary)
            }
            .buttonStyle(.plain)
            .disabled(!canGoForward)
        }
    }

    private var canGoForward: Bool {
        let next = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
        return next <= Calendar.current.startOfMonth(for: Date())
    }

    private var weekdayRow: some View {
        HStack(spacing: 4) {
            ForEach(weekdayLabels, id: \.self) { label in
                Text(label)
                    .font(.caption).foregroundStyle(.textTertiary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var leadingEmptyCells: [Int] {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: displayedMonth)
        return Array(0..<(weekday - 1))
    }

    private var daysInMonth: [Date] {
        let cal = Calendar.current
        guard let range = cal.range(of: .day, in: .month, for: displayedMonth) else { return [] }
        return range.compactMap { day -> Date? in
            cal.date(byAdding: .day, value: day - 1, to: displayedMonth)
        }
    }

    private var legend: some View {
        HStack(spacing: Spacing.sm) {
            Text("Score:")
                .font(.caption).foregroundStyle(.textTertiary)
            legendItem(color: .scoreExcellent, label: "85+")
            legendItem(color: .scoreGood, label: "70+")
            legendItem(color: .scoreFair, label: "50+")
            legendItem(color: .scorePoor, label: "<50")
            legendItem(color: .sleepElevated, label: "None")
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 3) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label).font(.caption).foregroundStyle(.textTertiary)
        }
    }
}

struct CalendarDayCell: View {
    let date: Date
    let session: SleepSession?
    let onTap: () -> Void

    private var isToday: Bool { Calendar.current.isDateInToday(date) }
    private var isFuture: Bool { date > Date() }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(cellBackground)
                if isToday {
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Color.sleepPurpleLight, lineWidth: 1.5)
                }
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.caption).fontWeight(isToday ? .bold : .regular)
                    .foregroundStyle(textColor)
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(.plain)
        .disabled(session == nil || isFuture)
    }

    private var cellBackground: Color {
        if isFuture { return .sleepSurface.opacity(0.3) }
        guard let score = session?.score?.overallScore else { return .sleepElevated }
        return Color.scoreColor(for: score).opacity(0.75)
    }

    private var textColor: Color {
        if isFuture { return .textTertiary }
        if session != nil { return .white }
        return .textTertiary
    }
}

private extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let comps = dateComponents([.year, .month], from: date)
        return self.date(from: comps) ?? date
    }
}

private extension Date {
    var monthYearString: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        return fmt.string(from: self)
    }
}
