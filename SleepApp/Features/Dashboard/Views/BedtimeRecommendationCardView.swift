import SwiftUI

struct BedtimeRecommendationCardView: View {
    let windows: [BedtimeWindow]
    let wakeTime: String

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(spacing: Spacing.xs) {
                    ZStack {
                        Circle().fill(Color.sleepTeal.opacity(0.15)).frame(width: 32, height: 32)
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.sleepTealLight)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Bedtime Windows")
                            .font(.titleSmall).fontWeight(.semibold).foregroundStyle(.textPrimary)
                        Text("Wake at \(wakeTime) feeling refreshed")
                            .font(.caption).foregroundStyle(.textTertiary)
                    }
                }

                Divider().overlay(Color.sleepBorder)

                VStack(spacing: Spacing.xs) {
                    ForEach(Array(windows.enumerated()), id: \.offset) { index, window in
                        windowRow(window: window, isRecommended: index == 0)
                        if index < windows.count - 1 {
                            Divider().overlay(Color.sleepBorder).padding(.leading, 44)
                        }
                    }
                }

                Text("Based on your average sleep cycle length")
                    .font(.caption).foregroundStyle(.textTertiary)
            }
        }
    }

    private func windowRow(window: BedtimeWindow, isRecommended: Bool) -> some View {
        HStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(isRecommended ? Color.sleepTeal.opacity(0.2) : Color.sleepElevated)
                    .frame(width: 36, height: 36)
                Text("\(window.cycleCount)")
                    .font(.titleSmall).fontWeight(.bold)
                    .foregroundStyle(isRecommended ? .sleepTealLight : .textSecondary)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Spacing.xs) {
                    Text(window.formattedBedtime)
                        .font(.titleSmall).fontWeight(.semibold).foregroundStyle(.textPrimary)
                    if isRecommended {
                        Text("Recommended")
                            .font(.caption).foregroundStyle(.sleepTealLight)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background { Capsule().fill(Color.sleepTeal.opacity(0.15)) }
                    }
                }
                Text("\(window.cycleCount) cycles · \(window.formattedDuration) sleep")
                    .font(.caption).foregroundStyle(.textTertiary)
            }
            Spacer()
        }
    }
}
