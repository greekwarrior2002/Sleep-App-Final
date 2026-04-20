import SwiftUI
import WidgetKit

struct SleepWidgetView: View {
    let entry: SleepWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemSmall: smallWidget
        case .systemMedium: mediumWidget
        case .accessoryCircular: circularWidget
        case .accessoryRectangular: rectangularWidget
        default: smallWidget
        }
    }

    // MARK: - Small Widget
    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(scoreColor)
                Text("Slumber")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(entry.score)")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(scoreColor)
                .monospacedDigit()
            Text(entry.grade)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(scoreColor)
                .textCase(.uppercase)
                .kerning(0.8)
            HStack(spacing: 3) {
                Image(systemName: trendIcon)
                    .font(.system(size: 9, weight: .bold))
                Text(entry.duration)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.black)
    }

    // MARK: - Medium Widget
    private var mediumWidget: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(scoreColor)
                    Text("Sleep Score")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                Text("\(entry.score)")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(scoreColor)
                    .monospacedDigit()
                Text(entry.grade.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(scoreColor)
                    .kerning(1)
                Text(entry.sleepDate)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            Divider().background(Color.white.opacity(0.1))

            VStack(alignment: .leading, spacing: 8) {
                metricRow(icon: "clock.fill", label: "Duration", value: entry.duration)
                metricRow(icon: trendIcon, label: "Trend", value: entry.trend.capitalized)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.black)
    }

    // MARK: - Accessory Circular (Lock Screen)
    private var circularWidget: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 1) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(scoreColor)
                Text("\(entry.score)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .monospacedDigit()
            }
        }
    }

    // MARK: - Accessory Rectangular (Lock Screen)
    private var rectangularWidget: some View {
        HStack(spacing: 8) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary)
            VStack(alignment: .leading, spacing: 1) {
                Text("Sleep Score: \(entry.score)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.primary)
                Text("\(entry.duration) · \(entry.grade)")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private func metricRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 14)
            VStack(alignment: .leading, spacing: 0) {
                Text(label).font(.system(size: 9)).foregroundStyle(.secondary)
                Text(value).font(.system(size: 12, weight: .semibold)).foregroundStyle(.primary)
            }
        }
    }

    private var scoreColor: Color {
        switch entry.score {
        case 85...: return Color(red: 0.655, green: 0.545, blue: 0.98)
        case 70..<85: return Color(red: 0.369, green: 0.918, blue: 0.831)
        case 50..<70: return Color(red: 0.988, green: 0.631, blue: 0.271)
        default: return Color(red: 0.863, green: 0.149, blue: 0.149)
        }
    }

    private var trendIcon: String {
        switch entry.trend {
        case "improving": return "arrow.up.right"
        case "declining": return "arrow.down.right"
        default: return "minus"
        }
    }
}
