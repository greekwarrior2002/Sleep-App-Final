import SwiftUI
import Charts

struct SleepNightDetailView: View {
    let session: SleepSession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sleepBackground.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.lg) {
                        scoreSection
                        durationSection
                        stagesSection
                        if let _ = session.heartRateVariability {
                            hrvSection
                        }
                        sourceSection
                        Spacer(minLength: Spacing.xxl)
                    }
                    .padding(Spacing.md)
                }
            }
            .navigationTitle(session.endDate.relativeDescription)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.sleepPurpleLight)
                }
            }
        }
    }

    private var scoreSection: some View {
        GlassCard {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Sleep Score")
                        .font(.labelSmall)
                        .textCase(.uppercase)
                        .kerning(0.8)
                        .foregroundStyle(.textTertiary)
                    if let score = session.score {
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text("\(score.overallScore)")
                                .font(.displaySmall)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.scoreColor(for: score.overallScore))
                                .monoDigits()
                            Text("/ 100")
                                .font(.bodyMedium)
                                .foregroundStyle(.textSecondary)
                        }
                        Text(score.grade)
                            .font(.bodyMedium)
                            .foregroundStyle(Color.scoreColor(for: score.overallScore))
                    } else {
                        Text("—")
                            .font(.displaySmall)
                            .foregroundStyle(.textTertiary)
                    }
                }
                Spacer()
                if let score = session.score {
                    scoreBreakdown(score)
                }
            }
        }
    }

    private func scoreBreakdown(_ score: SleepScore) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            scoreRow(label: "Duration", value: score.durationScore)
            scoreRow(label: "Quality", value: score.qualityScore)
            scoreRow(label: "Consistency", value: score.consistencyScore)
            scoreRow(label: "Recovery", value: score.recoveryScore)
        }
    }

    private func scoreRow(label: String, value: Int) -> some View {
        HStack(spacing: Spacing.xs) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.textTertiary)
            Text("\(value)")
                .font(.labelLarge)
                .fontWeight(.semibold)
                .foregroundStyle(Color.scoreColor(for: value))
                .monoDigits()
                .frame(width: 28, alignment: .trailing)
        }
    }

    private var durationSection: some View {
        GlassCard {
            HStack(spacing: Spacing.lg) {
                detailStat(label: "In Bed", value: session.timeInBed.hoursAndMinutes, icon: "bed.double.fill")
                Divider().frame(height: 40).overlay(Color.sleepBorder)
                detailStat(label: "Asleep", value: session.formattedDuration, icon: "moon.fill")
                Divider().frame(height: 40).overlay(Color.sleepBorder)
                detailStat(label: "Efficiency", value: "\(Int(session.sleepEfficiency * 100))%", icon: "waveform.path.ecg")
            }
        }
    }

    private func detailStat(label: String, value: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.sleepPurpleLight)
            Text(value)
                .font(.titleSmall)
                .fontWeight(.semibold)
                .foregroundStyle(.textPrimary)
                .monoDigits()
            Text(label)
                .font(.caption)
                .foregroundStyle(.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private var stagesSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                SectionHeaderView(title: "Sleep Stages")

                ForEach(stageRows, id: \.stage) { row in
                    stageProgressRow(row)
                }
            }
        }
    }

    private struct StageRow {
        let stage: String
        let color: Color
        let duration: TimeInterval
        let percent: Double
    }

    private var stageRows: [StageRow] {
        [
            StageRow(stage: "Deep", color: .stageDeep, duration: session.deepSleepDuration, percent: session.deepSleepPercent),
            StageRow(stage: "REM", color: .stageREM, duration: session.remSleepDuration, percent: session.remSleepPercent),
            StageRow(stage: "Light", color: .stageLight, duration: session.lightSleepDuration, percent: session.lightSleepPercent),
            StageRow(stage: "Awake", color: .stageAwake, duration: session.awakeDuration, percent: session.awakePercent)
        ]
    }

    private func stageProgressRow(_ row: StageRow) -> some View {
        HStack(spacing: Spacing.sm) {
            HStack(spacing: 6) {
                Circle().fill(row.color).frame(width: 8, height: 8)
                Text(row.stage)
                    .font(.bodyMedium)
                    .foregroundStyle(.textSecondary)
                    .frame(width: 44, alignment: .leading)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(Color.sleepElevated)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(row.color)
                        .frame(width: max(geo.size.width * row.percent, 0))
                }
            }
            .frame(height: 6)

            Text(row.duration.hoursAndMinutes)
                .font(.labelLarge)
                .fontWeight(.medium)
                .foregroundStyle(.textPrimary)
                .monoDigits()
                .frame(width: 50, alignment: .trailing)

            Text("\(Int(row.percent * 100))%")
                .font(.caption)
                .foregroundStyle(.textTertiary)
                .frame(width: 30, alignment: .trailing)
        }
    }

    private var hrvSection: some View {
        GlassCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Heart Rate Variability")
                        .font(.titleSmall)
                        .foregroundStyle(.textPrimary)
                    Text("Higher is generally better")
                        .font(.caption)
                        .foregroundStyle(.textTertiary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(session.heartRateVariability ?? 0)) ms")
                        .font(.displaySmall)
                        .fontWeight(.bold)
                        .foregroundStyle(.positive)
                        .monoDigits()
                    if let hr = session.averageHeartRate {
                        Text("Avg HR: \(Int(hr)) bpm")
                            .font(.caption)
                            .foregroundStyle(.textTertiary)
                    }
                }
            }
        }
    }

    private var sourceSection: some View {
        HStack {
            Image(systemName: "app.connected.to.app.below.fill")
                .font(.system(size: 12))
                .foregroundStyle(.textTertiary)
            Text("Source: \(session.sourceApp)")
                .font(.caption)
                .foregroundStyle(.textTertiary)
            Spacer()
            Text(session.startDate.timeString + " – " + session.endDate.timeString)
                .font(.caption)
                .foregroundStyle(.textTertiary)
        }
        .padding(.horizontal, Spacing.xs)
    }
}
