import SwiftUI

struct MetricCard: View {
    let title: String
    let value: String
    let unit: String
    var icon: String? = nil
    var iconColor: Color = .sleepPurpleLight
    var trend: TrendDirection? = nil

    enum TrendDirection {
        case up, down, neutral
        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "minus"
            }
        }
        var color: Color {
            switch self {
            case .up: return .positive
            case .down: return .scorePoor
            case .neutral: return .textTertiary
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(iconColor)
                }
                Text(title)
                    .font(.labelSmall)
                    .foregroundStyle(.textSecondary)
                Spacer()
                if let trend {
                    Image(systemName: trend.icon)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(trend.color)
                }
            }

            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(value)
                    .font(.titleLarge)
                    .fontWeight(.bold)
                    .foregroundStyle(.textPrimary)
                    .monoDigits()

                Text(unit)
                    .font(.labelSmall)
                    .foregroundStyle(.textSecondary)
            }
        }
        .glassCard()
    }
}

struct SmallMetricView: View {
    let label: String
    let value: String
    var color: Color = .sleepPurpleLight

    var body: some View {
        VStack(spacing: Spacing.xxs) {
            Text(value)
                .font(.titleMedium)
                .fontWeight(.semibold)
                .foregroundStyle(color)
                .monoDigits()
            Text(label)
                .font(.caption)
                .foregroundStyle(.textTertiary)
        }
    }
}
