import SwiftUI

struct SleepScoreRingView: View {
    let score: SleepScore?
    var session: SleepSession?
    @State private var animatedScore: Double = 0
    @State private var hasAppeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var scoreValue: Int { score?.overallScore ?? 0 }
    private var ringColor: Color { .scoreColor(for: scoreValue) }
    private var ringProgress: Double { Double(scoreValue) / 100.0 }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            ZStack {
                ringBackground
                ringForeground
                scoreCenter
            }
            .frame(width: 200, height: 200)

            if let session {
                sessionStats(session)
            }
        }
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            if reduceMotion {
                animatedScore = Double(scoreValue)
            } else {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2)) {
                    animatedScore = Double(scoreValue)
                }
            }
        }
        .onChange(of: scoreValue) { _, new in
            if reduceMotion {
                animatedScore = Double(new)
            } else {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    animatedScore = Double(new)
                }
            }
        }
    }

    private var ringBackground: some View {
        Circle()
            .stroke(Color.sleepElevated, lineWidth: 14)
    }

    private var ringForeground: some View {
        Circle()
            .trim(from: 0, to: animatedScore / 100.0)
            .stroke(
                LinearGradient(
                    colors: ringGradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                style: StrokeStyle(lineWidth: 14, lineCap: .round)
            )
            .rotationEffect(.degrees(-90))
            .shadow(color: ringColor.opacity(0.4), radius: 8)
    }

    private var ringGradientColors: [Color] {
        switch scoreValue {
        case 85...: return [Color(hex: "A78BFA"), Color(hex: "7C3AED")]
        case 70..<85: return [Color(hex: "5EEAD4"), Color(hex: "0D9488")]
        case 50..<70: return [Color(hex: "FCD34D"), Color(hex: "D97706")]
        default: return [Color(hex: "FCA5A5"), Color(hex: "DC2626")]
        }
    }

    private var scoreCenter: some View {
        VStack(spacing: 2) {
            Text("\(Int(animatedScore))")
                .font(.displayMedium)
                .fontWeight(.bold)
                .foregroundStyle(.textPrimary)
                .monoDigits()
                .contentTransition(.numericText())

            Text(score?.grade ?? "No Data")
                .font(.labelSmall)
                .fontWeight(.semibold)
                .foregroundStyle(scoreValue > 0 ? ringColor : .textTertiary)
                .textCase(.uppercase)
                .kerning(1.2)

            if let trend = score?.trend, scoreValue > 0 {
                HStack(spacing: 2) {
                    Image(systemName: trend.icon)
                        .font(.system(size: 9, weight: .bold))
                    Text(trend.rawValue.capitalized)
                        .font(.caption)
                }
                .foregroundStyle(.textTertiary)
            }
        }
    }

    private func sessionStats(_ session: SleepSession) -> some View {
        HStack(spacing: Spacing.xxl) {
            SmallMetricView(
                label: "Duration",
                value: session.formattedDuration,
                color: .sleepTealLight
            )

            Divider()
                .frame(height: 32)
                .overlay(Color.sleepBorder)

            SmallMetricView(
                label: "Efficiency",
                value: "\(Int(session.sleepEfficiency * 100))%",
                color: .sleepPurpleLight
            )

            if let hrv = session.heartRateVariability {
                Divider()
                    .frame(height: 32)
                    .overlay(Color.sleepBorder)

                SmallMetricView(
                    label: "HRV",
                    value: "\(Int(hrv))ms",
                    color: .positive
                )
            }
        }
    }
}

struct NoDataRingView: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            ZStack {
                Circle()
                    .stroke(Color.sleepElevated, lineWidth: 14)
                    .frame(width: 200, height: 200)

                VStack(spacing: Spacing.xs) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.textTertiary)
                    Text("No sleep data")
                        .font(.titleSmall)
                        .foregroundStyle(.textSecondary)
                    Text("Sync with Apple Health")
                        .font(.bodyMedium)
                        .foregroundStyle(.textTertiary)
                }
            }
        }
    }
}
