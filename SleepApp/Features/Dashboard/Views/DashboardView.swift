import SwiftUI
import SwiftData

struct DashboardView: View {
    @Binding var showLogSheet: Bool
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel: DashboardViewModel
    @State private var selectedTab: AppTab = .insights

    init(showLogSheet: Binding<Bool>) {
        self._showLogSheet = showLogSheet
        // ViewModel is initialized in onAppear with context
        self._viewModel = StateObject(wrappedValue: DashboardViewModel(context: ModelContext(try! ModelContainer(for: SleepSession.self, DailyLog.self, SleepInsight.self, SleepScore.self))))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sleepBackground.ignoresSafeArea()

                if viewModel.isLoading && viewModel.recentSessions.isEmpty {
                    loadingView
                } else {
                    mainContent
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
        }
        .task { await viewModel.load() }
    }

    private var mainContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Spacing.lg) {
                headerSection
                heroSection
                statsRow
                recentChart
                insightCard
                if !viewModel.hasCheckedInToday {
                    checkinCard
                }
                Spacer(minLength: 100)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.sm)
        }
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.greeting)
                    .font(.titleSmall)
                    .foregroundStyle(.textSecondary)
                Text(Date().shortDate)
                    .font(.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundStyle(.textPrimary)
            }
            Spacer()
            Button {
                Task { await viewModel.syncHealthKit() }
            } label: {
                HStack(spacing: 4) {
                    if viewModel.isSyncing {
                        ProgressView().tint(.sleepPurpleLight).scaleEffect(0.75)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 14, weight: .medium))
                    }
                    Text("Sync")
                        .font(.labelLarge)
                }
                .foregroundStyle(.sleepPurpleLight)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xxs)
                .background {
                    Capsule()
                        .fill(Color.sleepPurpleDim)
                }
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isSyncing)
        }
    }

    private var heroSection: some View {
        GlassCard {
            VStack(spacing: Spacing.lg) {
                if let session = viewModel.lastNightSession {
                    VStack(spacing: Spacing.xxs) {
                        Text("Last Night")
                            .font(.labelSmall)
                            .textCase(.uppercase)
                            .kerning(1)
                            .foregroundStyle(.textTertiary)
                        Text(session.endDate.relativeDescription)
                            .font(.bodyMedium)
                            .foregroundStyle(.textSecondary)
                    }

                    SleepScoreRingView(score: viewModel.lastNightScore, session: session)

                    if session.deepSleepPercent > 0 || session.remSleepPercent > 0 {
                        stageBreakdownRow(session: session)
                    }
                } else {
                    NoDataRingView()
                    PrimaryButton(title: "Sync Health Data", icon: "heart.fill") {
                        Task { await viewModel.syncHealthKit() }
                    }
                }
            }
        }
    }

    private func stageBreakdownRow(session: SleepSession) -> some View {
        HStack(spacing: Spacing.lg) {
            stageStat(color: .stageDeep, label: "Deep", value: session.deepSleepDuration.hoursAndMinutes)
            stageStat(color: .stageREM, label: "REM", value: session.remSleepDuration.hoursAndMinutes)
            stageStat(color: .stageLight, label: "Light", value: session.lightSleepDuration.hoursAndMinutes)
        }
        .padding(.top, Spacing.xxs)
    }

    private func stageStat(color: Color, label: String, value: String) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Circle().fill(color).frame(width: 7, height: 7)
                Text(label).font(.caption).foregroundStyle(.textTertiary)
            }
            Text(value).font(.labelLarge).fontWeight(.semibold).foregroundStyle(.textPrimary).monoDigits()
        }
        .frame(maxWidth: .infinity)
    }

    private var statsRow: some View {
        HStack(spacing: Spacing.sm) {
            MetricCard(
                title: "7-Day Avg",
                value: "\(viewModel.weeklyAvgScore)",
                unit: "score",
                icon: "chart.line.uptrend.xyaxis",
                iconColor: .sleepPurpleLight
            )
            MetricCard(
                title: "Nights Logged",
                value: "\(viewModel.recentSessions.count)",
                unit: "days",
                icon: "moon.fill",
                iconColor: .sleepTealLight
            )
        }
    }

    @ViewBuilder
    private var recentChart: some View {
        if !viewModel.last7Sessions.isEmpty {
            RecentNightsChartView(sessions: viewModel.last7Sessions)
        }
    }

    private var insightCard: some View {
        InsightCardView(insight: viewModel.currentInsight) {
            selectedTab = .insights
        }
    }

    private var checkinCard: some View {
        QuickCheckinView { mood in
            Task { await viewModel.saveCheckin(mood: mood) }
        }
    }

    private var loadingView: some View {
        VStack(spacing: Spacing.lg) {
            LoadingRingView()
                .frame(width: 48, height: 48)
            Text("Loading your sleep data…")
                .font(.bodyMedium)
                .foregroundStyle(.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("Slumber")
                .font(.titleMedium)
                .fontWeight(.semibold)
                .foregroundStyle(.textPrimary)
        }
    }
}
