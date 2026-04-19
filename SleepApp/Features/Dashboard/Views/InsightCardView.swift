import SwiftUI

struct InsightCardView: View {
    let insight: SleepInsight?
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button {
            onTap?()
        } label: {
            GlassCard {
                HStack(alignment: .top, spacing: Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(Color.sleepPurpleDim)
                            .frame(width: 36, height: 36)
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.sleepPurpleLight)
                    }

                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        HStack {
                            Text("AI Insight")
                                .font(.labelSmall)
                                .fontWeight(.semibold)
                                .foregroundStyle(.sleepPurpleLight)
                                .textCase(.uppercase)
                                .kerning(0.8)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.textTertiary)
                        }

                        if let insight {
                            Text(insight.summary)
                                .font(.bodyMedium)
                                .foregroundStyle(.textSecondary)
                                .lineLimit(3)
                                .multilineTextAlignment(.leading)
                        } else {
                            Text("Sync sleep data to generate your personalized AI insights.")
                                .font(.bodyMedium)
                                .foregroundStyle(.textTertiary)
                                .lineLimit(2)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct QuickCheckinView: View {
    let onSelect: (Int) -> Void

    private let moods: [(emoji: String, label: String, value: Int)] = [
        ("😴", "Groggy", 1),
        ("😪", "Tired", 2),
        ("😐", "Ok", 3),
        ("🙂", "Rested", 4),
        ("😄", "Great", 5)
    ]

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("How do you feel this morning?")
                    .font(.titleSmall)
                    .foregroundStyle(.textPrimary)

                HStack(spacing: 0) {
                    ForEach(moods, id: \.value) { mood in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                onSelect(mood.value)
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Text(mood.emoji)
                                    .font(.system(size: 26))
                                Text(mood.label)
                                    .font(.caption)
                                    .foregroundStyle(.textTertiary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

struct StageBreakdownMiniView: View {
    let session: SleepSession

    var body: some View {
        HStack(spacing: 4) {
            stageBar(pct: session.deepSleepPercent, color: .stageDeep, label: "Deep")
            stageBar(pct: session.remSleepPercent, color: .stageREM, label: "REM")
            stageBar(pct: session.lightSleepPercent, color: .stageLight, label: "Light")
            if session.awakePercent > 0.02 {
                stageBar(pct: session.awakePercent, color: .stageAwake, label: "Awake")
            }
        }
        .frame(height: 8)
        .clipShape(Capsule())
    }

    private func stageBar(pct: Double, color: Color, label: String) -> some View {
        Rectangle()
            .fill(color)
            .frame(maxWidth: .infinity)
            .scaleEffect(x: CGFloat(pct > 0 ? 1 : 0), anchor: .leading)
    }
}
