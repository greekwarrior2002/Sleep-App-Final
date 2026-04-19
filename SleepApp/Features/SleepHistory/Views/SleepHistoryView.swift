import SwiftUI
import SwiftData

struct SleepHistoryView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = SleepHistoryViewModel()
    @State private var selectedSession: SleepSession?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sleepBackground.ignoresSafeArea()
                content
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            viewModel.setup(context: context)
            await viewModel.load()
        }
        .sheet(item: $selectedSession) { session in
            SleepNightDetailView(session: session)
        }
    }

    private var content: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Spacing.lg) {
                periodPicker
                    .padding(.horizontal, Spacing.md)

                if viewModel.sessions.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: Spacing.md) {
                        SleepBarChartView(
                            sessions: viewModel.displaySessions,
                            period: viewModel.selectedPeriod,
                            selectedSession: $selectedSession
                        )
                        if viewModel.displaySessions.count >= 3 {
                            StageAreaChartView(sessions: viewModel.displaySessions)
                        }
                        StatsCardView(viewModel: viewModel)
                        nightsList
                    }
                    .padding(.horizontal, Spacing.md)
                }
                Spacer(minLength: 100)
            }
            .padding(.top, Spacing.sm)
        }
    }

    private var periodPicker: some View {
        HStack(spacing: 0) {
            ForEach(SleepHistoryViewModel.Period.allCases, id: \.rawValue) { period in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.selectedPeriod = period
                    }
                    Task { await viewModel.load() }
                } label: {
                    Text(period.label)
                        .font(.labelLarge)
                        .foregroundStyle(viewModel.selectedPeriod == period ? .white : Color.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.xs)
                        .background {
                            if viewModel.selectedPeriod == period {
                                RoundedRectangle(cornerRadius: Radius.sm)
                                    .fill(Color.sleepPurple)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background {
            RoundedRectangle(cornerRadius: Radius.md)
                .fill(Color.sleepSurface)
                .overlay {
                    RoundedRectangle(cornerRadius: Radius.md)
                        .strokeBorder(Color.sleepBorder, lineWidth: 1)
                }
        }
    }

    private var nightsList: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                SectionHeaderView(title: "All Nights")
                LazyVStack(spacing: 0) {
                    ForEach(Array(viewModel.displaySessions.reversed().enumerated()), id: \.element.id) { index, session in
                        SleepNightRowView(session: session) {
                            selectedSession = session
                        }
                        if index < viewModel.displaySessions.count - 1 {
                            Divider().overlay(Color.sleepBorder).padding(.leading, 48)
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "moon.zzz")
                .font(.system(size: 48))
                .foregroundStyle(.textTertiary)
            Text("No sleep data")
                .font(.titleMedium)
                .foregroundStyle(.textSecondary)
            Text("Sync your health data from the Dashboard to see your sleep history.")
                .font(.bodyMedium)
                .foregroundStyle(.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Spacing.xxxl)
    }
}

struct SleepNightRowView: View {
    let session: SleepSession
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(scoreColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Text("\(session.score?.overallScore ?? 0)")
                        .font(.labelLarge)
                        .fontWeight(.bold)
                        .foregroundStyle(scoreColor)
                        .monoDigits()
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.endDate.relativeDescription)
                        .font(.titleSmall)
                        .foregroundStyle(.textPrimary)
                    Text(session.startDate.timeString + " → " + session.endDate.timeString)
                        .font(.caption)
                        .foregroundStyle(.textTertiary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(session.formattedDuration)
                        .font(.titleSmall)
                        .fontWeight(.semibold)
                        .foregroundStyle(.textPrimary)
                        .monoDigits()
                    Text(session.sourceApp)
                        .font(.caption)
                        .foregroundStyle(.textTertiary)
                        .lineLimit(1)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.textTertiary)
            }
            .padding(.vertical, Spacing.sm)
        }
        .buttonStyle(.plain)
    }

    private var scoreColor: Color { .scoreColor(for: session.score?.overallScore ?? 0) }
}
