import SwiftUI

struct SleepDebtCardView: View {
    let debt: SleepDebtResult

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(spacing: Spacing.xs) {
                    ZStack {
                        Circle().fill(debtColor.opacity(0.15)).frame(width: 32, height: 32)
                        Image(systemName: "bed.double.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(debtColor)
                    }
                    Text("Sleep Debt")
                        .font(.titleSmall).fontWeight(.semibold).foregroundStyle(.textPrimary)
                    Spacer()
                    Text("7-day")
                        .font(.caption).foregroundStyle(.textTertiary)
                        .padding(.horizontal, Spacing.xs).padding(.vertical, 3)
                        .background { Capsule().fill(Color.sleepElevated) }
                }

                Divider().overlay(Color.sleepBorder)

                if debt.isInDebt {
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                        Text(debt.formattedDebt)
                            .font(.displaySmall).fontWeight(.bold)
                            .foregroundStyle(debtColor).monoDigits()
                        Text("owed")
                            .font(.bodyMedium).foregroundStyle(.textSecondary)
                        Spacer()
                    }
                    debtGauge
                    Text("Avg \(String(format: "%.1f", debt.averageActualHours))h vs \(String(format: "%.1f", debt.goalHours))h goal")
                        .font(.caption).foregroundStyle(.textTertiary)
                } else {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.positive)
                        Text("No sleep debt this week — great work!")
                            .font(.bodyMedium).foregroundStyle(.textSecondary)
                    }
                }
            }
        }
    }

    private var debtColor: Color {
        switch debt.debtLevel {
        case .none: return .positive
        case .mild: return .positive
        case .moderate: return .scoreFair
        case .severe: return .scorePoor
        }
    }

    private var debtGauge: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.sleepElevated)
                    .frame(height: 6)
                RoundedRectangle(cornerRadius: 4)
                    .fill(debtColor)
                    .frame(width: min(CGFloat(debt.debtHours / (debt.goalHours * 7)) * geo.size.width, geo.size.width), height: 6)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: debt.debtHours)
            }
        }
        .frame(height: 6)
    }
}
