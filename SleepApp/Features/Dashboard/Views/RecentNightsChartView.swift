import SwiftUI
import Charts

struct RecentNightsChartView: View {
    let sessions: [SleepSession]
    @State private var selectedSession: SleepSession?
    @AppStorage(Constants.UserDefaults.sleepGoalKey) var sleepGoalHours: Double = 8.0

    private var chartData: [ChartEntry] {
        sessions.map { session in
            ChartEntry(
                date: session.calendarDate,
                hours: session.durationHours,
                score: session.score?.overallScore ?? 0,
                label: session.calendarDate.shortWeekday
            )
        }
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                SectionHeaderView(title: "Last 7 Nights")

                Chart(chartData) { entry in
                    BarMark(
                        x: .value("Day", entry.label),
                        y: .value("Hours", entry.hours)
                    )
                    .foregroundStyle(barColor(score: entry.score))
                    .cornerRadius(4)
                    .annotation(position: .top) {
                        if selectedSession?.calendarDate == entry.date {
                            callout(entry: entry)
                        }
                    }

                    RuleMark(y: .value("Goal", sleepGoalHours))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .foregroundStyle(Color.textTertiary.opacity(0.5))
                        .annotation(position: .trailing, alignment: .leading) {
                            Text("Goal")
                                .font(.caption)
                                .foregroundStyle(.textTertiary)
                        }
                }
                .frame(height: 100)
                .chartYScale(domain: 0...(sleepGoalHours + 2))
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let str = value.as(String.self) {
                                Text(str)
                                    .font(.caption)
                                    .foregroundStyle(Color.textTertiary)
                            }
                        }
                    }
                }
                .chartYAxis(.hidden)
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        Rectangle().fill(.clear).contentShape(Rectangle())
                            .gesture(DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let xPosition = value.location.x
                                    if let label = proxy.value(atX: xPosition, as: String.self) {
                                        selectedSession = sessions.first {
                                            $0.calendarDate.shortWeekday == label
                                        }
                                    }
                                }
                                .onEnded { _ in
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        selectedSession = nil
                                    }
                                }
                            )
                    }
                }

                stageLegend
            }
        }
    }

    private func barColor(score: Int) -> LinearGradient {
        let base: Color = .scoreColor(for: score)
        return LinearGradient(
            colors: [base.opacity(0.8), base],
            startPoint: .bottom,
            endPoint: .top
        )
    }

    private func callout(entry: ChartEntry) -> some View {
        VStack(spacing: 2) {
            Text(String(format: "%.1fh", entry.hours))
                .font(.labelSmall)
                .fontWeight(.semibold)
                .foregroundStyle(.textPrimary)
            Text("\(entry.score)")
                .font(.caption)
                .foregroundStyle(.textSecondary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background {
            RoundedRectangle(cornerRadius: Radius.sm)
                .fill(Color.sleepElevated)
                .overlay {
                    RoundedRectangle(cornerRadius: Radius.sm)
                        .strokeBorder(Color.sleepBorder, lineWidth: 1)
                }
        }
    }

    private var stageLegend: some View {
        HStack(spacing: Spacing.sm) {
            legendDot(color: .scoreExcellent, label: "85+")
            legendDot(color: .scoreGood, label: "70-84")
            legendDot(color: .scoreFair, label: "50-69")
            legendDot(color: .scorePoor, label: "<50")
            Spacer()
        }
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label).font(.caption).foregroundStyle(.textTertiary)
        }
    }
}

private struct ChartEntry: Identifiable {
    let id = UUID()
    let date: Date
    let hours: Double
    let score: Int
    let label: String
}
