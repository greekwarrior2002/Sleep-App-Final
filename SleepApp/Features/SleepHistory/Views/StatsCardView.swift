import SwiftUI

struct StatsCardView: View {
    let viewModel: SleepHistoryViewModel

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                SectionHeaderView(title: "Period Averages")

                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: Spacing.sm
                ) {
                    StatCell(
                        icon: "moon.zzz.fill",
                        iconColor: .sleepPurpleLight,
                        label: "Avg Duration",
                        value: String(format: "%.1fh", viewModel.averageDurationHours)
                    )
                    StatCell(
                        icon: "star.fill",
                        iconColor: .scoreFair,
                        label: "Avg Score",
                        value: "\(viewModel.averageScore)"
                    )
                    StatCell(
                        icon: "waveform.path.ecg",
                        iconColor: .positive,
                        label: "Deep Sleep",
                        value: "\(Int(viewModel.averageDeepPercent * 100))%"
                    )
                    StatCell(
                        icon: "heart.fill",
                        iconColor: .scorePoor,
                        label: "Efficiency",
                        value: "\(Int(viewModel.averageEfficiency * 100))%"
                    )
                    if let hrv = viewModel.averageHRV {
                        StatCell(
                            icon: "waveform",
                            iconColor: .sleepTealLight,
                            label: "Avg HRV",
                            value: "\(Int(hrv)) ms"
                        )
                    }
                }
            }
        }
    }
}

struct StatCell: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.textTertiary)
                Text(value)
                    .font(.titleSmall)
                    .fontWeight(.semibold)
                    .foregroundStyle(.textPrimary)
                    .monoDigits()
            }
        }
        .padding(Spacing.xs)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: Radius.sm)
                .fill(Color.sleepElevated)
        }
    }
}
