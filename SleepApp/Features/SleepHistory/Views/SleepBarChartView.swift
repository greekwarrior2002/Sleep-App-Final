import SwiftUI
import Charts

struct SleepBarChartView: View {
    let sessions: [SleepSession]
    let period: SleepHistoryViewModel.Period
    @Binding var selectedSession: SleepSession?
    @AppStorage(Constants.UserDefaults.sleepGoalKey) var sleepGoalHours: Double = 8.0

    private var displaySessions: [SleepSession] {
        sessions.sorted { $0.startDate < $1.startDate }
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                SectionHeaderView(title: "Sleep Duration")

                Chart(displaySessions) { session in
                    BarMark(
                        x: .value("Date", session.calendarDate, unit: .day),
                        y: .value("Hours", session.durationHours)
                    )
                    .foregroundStyle(barGradient(session: session))
                    .cornerRadius(3)

                    RuleMark(y: .value("Goal", sleepGoalHours))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .foregroundStyle(Color.sleepPurple.opacity(0.4))
                }
                .frame(height: period == .quarter ? 120 : 140)
                .chartYScale(domain: 0...(sleepGoalHours + 2))
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: axisDayStride)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(date.shortWeekday)
                                    .font(.caption)
                                    .foregroundStyle(Color.textTertiary)
                            }
                        }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.sleepBorder)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .trailing, values: [0, 4, 6, 8, 10]) { value in
                        if let hours = value.as(Double.self) {
                            AxisValueLabel {
                                Text("\(Int(hours))h")
                                    .font(.caption)
                                    .foregroundStyle(Color.textTertiary)
                            }
                        }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.sleepBorder)
                    }
                }
                .chartScrollableAxes(period == .quarter ? .horizontal : [])
                .chartXVisibleDomain(length: 3600.0 * 24.0 * Double(period == .quarter ? 30 : period.rawValue))
                .chartOverlay { proxy in
                    GeometryReader { _ in
                        Rectangle().fill(.clear).contentShape(Rectangle())
                            .onTapGesture { location in }
                    }
                }

                goalLine
            }
        }
    }

    private var axisDayStride: Int {
        switch period {
        case .week: return 1
        case .month: return 5
        case .quarter: return 7
        }
    }

    private func barGradient(session: SleepSession) -> LinearGradient {
        let score = session.score?.overallScore ?? 0
        let color = Color.scoreColor(for: score)
        return LinearGradient(colors: [color.opacity(0.7), color], startPoint: .bottom, endPoint: .top)
    }

    private var goalLine: some View {
        HStack(spacing: 4) {
            Rectangle()
                .fill(Color.sleepPurple.opacity(0.4))
                .frame(width: 16, height: 1.5)
                .overlay {
                    HStack(spacing: 2) {
                        ForEach(0..<3, id: \.self) { _ in
                            Rectangle().fill(Color.clear).frame(width: 4)
                        }
                    }
                }
            Text("Sleep goal (\(String(format: "%.0f", sleepGoalHours))h)")
                .font(.caption)
                .foregroundStyle(.textTertiary)
        }
    }
}

struct StageAreaChartView: View {
    let sessions: [SleepSession]
    var period: SleepHistoryViewModel.Period = .week

    private var displaySessions: [SleepSession] {
        sessions.sorted { $0.startDate < $1.startDate }
    }

    private struct StagePoint: Identifiable {
        let id = UUID()
        let date: Date
        let stage: String
        let hours: Double
    }

    private var chartData: [StagePoint] {
        var points: [StagePoint] = []
        for session in displaySessions {
            let date = session.calendarDate
            points.append(StagePoint(date: date, stage: "Deep", hours: session.deepSleepDuration.hours))
            points.append(StagePoint(date: date, stage: "REM", hours: session.remSleepDuration.hours))
            points.append(StagePoint(date: date, stage: "Light", hours: session.lightSleepDuration.hours))
        }
        return points
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                SectionHeaderView(title: "Sleep Stages")

                Chart(chartData) { point in
                    AreaMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Hours", point.hours)
                    )
                    .foregroundStyle(by: .value("Stage", point.stage))
                    .interpolationMethod(period == .quarter ? .linear : .catmullRom)
                }
                .chartForegroundStyleScale([
                    "Deep": Color.stageDeep,
                    "REM": Color.stageREM,
                    "Light": Color.stageLight
                ])
                .frame(height: 100)
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(position: .trailing, values: [0, 2, 4]) { value in
                        if let h = value.as(Double.self) {
                            AxisValueLabel {
                                Text("\(Int(h))h").font(.caption).foregroundStyle(Color.textTertiary)
                            }
                        }
                    }
                }
                .chartLegend(position: .bottom, alignment: .leading) {
                    HStack(spacing: Spacing.sm) {
                        legendItem(color: .stageDeep, label: "Deep")
                        legendItem(color: .stageREM, label: "REM")
                        legendItem(color: .stageLight, label: "Light")
                    }
                }
            }
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .font(.caption)
                .foregroundStyle(.textSecondary)
        }
    }
}
