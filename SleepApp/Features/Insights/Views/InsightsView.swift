import SwiftUI
import SwiftData

struct InsightsView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = InsightsViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sleepBackground.ignoresSafeArea()
                content
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
        }
        .task {
            viewModel.setup(context: context)
            await viewModel.load()
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            loadingView
        } else {
            ScrollView(showsIndicators: false) {
                VStack(spacing: Spacing.lg) {
                    if !viewModel.hasAPIKey { apiKeyBanner }
                    if let error = viewModel.error { errorBanner(error) }
                    reportCard
                    if !combinedCorrelations.isEmpty { correlationSection }
                    if let insight = viewModel.currentInsight, !insight.recommendations.isEmpty {
                        recommendationsSection(insight.recommendations)
                    }
                    if viewModel.pastInsights.count > 1 { historySection }
                    Spacer(minLength: 100)
                }
                .padding(Spacing.md)
            }
        }
    }

    private var reportCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    HStack(spacing: Spacing.xs) {
                        ZStack {
                            Circle().fill(Color.sleepPurpleDim).frame(width: 32, height: 32)
                            Image(systemName: "sparkles")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.sleepPurpleLight)
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text("AI Sleep Report")
                                .font(.titleSmall)
                                .foregroundStyle(.textPrimary)
                            if let insight = viewModel.currentInsight {
                                Text(insight.periodDescription)
                                    .font(.caption)
                                    .foregroundStyle(.textTertiary)
                            }
                        }
                    }
                    Spacer()
                    if let insight = viewModel.currentInsight {
                        confidenceBadge(insight.confidencePercent)
                    }
                }

                Divider().overlay(Color.sleepBorder)

                if viewModel.isGenerating {
                    generatingState
                } else if let insight = viewModel.currentInsight {
                    Text(insight.summary)
                        .font(.bodyLarge)
                        .foregroundStyle(.textSecondary)
                        .lineSpacing(4)
                    if let trend = viewModel.currentInsight?.trend {
                        trendBadge(trend)
                    }
                } else {
                    emptyReportState
                }
            }
        }
    }

    private var generatingState: some View {
        HStack(spacing: Spacing.sm) {
            LoadingRingView().frame(width: 24, height: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text("Analyzing your sleep patterns…")
                    .font(.bodyMedium).foregroundStyle(.textSecondary)
                Text("This usually takes 5–15 seconds")
                    .font(.caption).foregroundStyle(.textTertiary)
            }
        }
        .padding(.vertical, Spacing.sm)
    }

    private var emptyReportState: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 32)).foregroundStyle(.textTertiary)
            Text("No insights yet")
                .font(.titleSmall).foregroundStyle(.textSecondary)
            Text("Sync sleep data and add lifestyle logs to generate personalized AI insights.")
                .font(.bodyMedium).foregroundStyle(.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
    }

    private func confidenceBadge(_ percent: Int) -> some View {
        Text("\(percent)% confidence")
            .font(.caption).foregroundStyle(.textTertiary)
            .padding(.horizontal, Spacing.xs).padding(.vertical, 3)
            .background { Capsule().fill(Color.sleepElevated) }
    }

    private func trendBadge(_ trend: ScoreTrend) -> some View {
        HStack(spacing: 4) {
            Image(systemName: trend.icon).font(.system(size: 11, weight: .semibold))
            Text(trend.rawValue.capitalized).font(.labelSmall).fontWeight(.semibold)
        }
        .foregroundStyle(trendColor(trend))
        .padding(.horizontal, Spacing.sm).padding(.vertical, 4)
        .background { Capsule().fill(trendColor(trend).opacity(0.15)) }
    }

    private func trendColor(_ trend: ScoreTrend) -> Color {
        switch trend {
        case .improving: return .positive
        case .stable: return .textSecondary
        case .declining: return .scorePoor
        }
    }

    private var correlationSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeaderView(title: "Detected Patterns").padding(.horizontal, Spacing.xxs)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(combinedCorrelations) { correlation in
                        CorrelationCardView(correlation: correlation).frame(width: 200)
                    }
                }
                .padding(.horizontal, Spacing.xxs)
            }
        }
    }

    private var combinedCorrelations: [CorrelationFinding] {
        let aiCorrelations = viewModel.currentInsight?.correlations ?? []
        var combined = aiCorrelations
        for local in viewModel.correlations {
            if !combined.contains(where: { $0.factor == local.factor }) {
                combined.append(local)
            }
        }
        return combined.sorted { abs($0.strength) > abs($1.strength) }
    }

    private func recommendationsSection(_ recs: [Recommendation]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeaderView(title: "Recommendations").padding(.horizontal, Spacing.xxs)
            VStack(spacing: Spacing.xs) {
                ForEach(recs.prefix(7)) { rec in RecommendationRowView(recommendation: rec) }
            }
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeaderView(title: "Past Reports").padding(.horizontal, Spacing.xxs)
            VStack(spacing: Spacing.xs) {
                ForEach(viewModel.pastInsights.dropFirst()) { insight in
                    InsightHistoryRow(insight: insight)
                }
            }
        }
    }

    private var apiKeyBanner: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "key.fill").foregroundStyle(.sleepPurpleLight)
            VStack(alignment: .leading, spacing: 2) {
                Text("Add API Key for AI Insights")
                    .font(.titleSmall).foregroundStyle(.textPrimary)
                Text("Add your Claude API key in Settings to enable AI analysis.")
                    .font(.caption).foregroundStyle(.textSecondary)
            }
        }
        .glassCard()
        .overlay {
            RoundedRectangle(cornerRadius: Radius.lg)
                .strokeBorder(Color.sleepPurple.opacity(0.4), lineWidth: 1)
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.warning)
            Text(message).font(.bodyMedium).foregroundStyle(.textSecondary)
        }
        .glassCard()
    }

    private var loadingView: some View {
        VStack(spacing: Spacing.lg) {
            LoadingRingView().frame(width: 48, height: 48)
            Text("Loading insights…").font(.bodyMedium).foregroundStyle(.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                Task { await viewModel.generateInsight() }
            } label: {
                HStack(spacing: 4) {
                    if viewModel.isGenerating {
                        ProgressView().tint(.sleepPurpleLight).scaleEffect(0.7)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                    Text("Refresh")
                }
                .font(.labelLarge)
                .foregroundStyle(.sleepPurpleLight)
            }
            .disabled(viewModel.isGenerating || !viewModel.hasAPIKey)
        }
    }
}

struct CorrelationCardView: View {
    let correlation: CorrelationFinding

    var body: some View {
        GlassCard(cornerRadius: Radius.lg) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Text(correlation.factor)
                        .font(.titleSmall).fontWeight(.semibold).foregroundStyle(.textPrimary)
                        .lineLimit(2)
                    Spacer(minLength: 0)
                    directionIcon
                }
                Text(correlation.effect)
                    .font(.bodyMedium).foregroundStyle(.textSecondary).lineLimit(3)
                HStack {
                    strengthBar
                    Spacer()
                    Text("\(correlation.occurrences) nights")
                        .font(.caption).foregroundStyle(.textTertiary)
                }
            }
        }
    }

    private var directionIcon: some View {
        Image(systemName: directionSymbol)
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(directionColor)
            .padding(6)
            .background { Circle().fill(directionColor.opacity(0.15)) }
    }

    private var directionSymbol: String {
        switch correlation.direction {
        case .negative: return "arrow.down.right"
        case .positive: return "arrow.up.right"
        case .neutral: return "minus"
        }
    }

    private var directionColor: Color {
        switch correlation.direction {
        case .negative: return .scorePoor
        case .positive: return .positive
        case .neutral: return .textSecondary
        }
    }

    private var strengthBar: some View {
        HStack(spacing: 3) {
            ForEach(0..<5) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(i < strengthDots ? directionColor : Color.sleepElevated)
                    .frame(width: 8, height: 8)
            }
        }
    }

    private var strengthDots: Int { Int(abs(correlation.strength) * 5).clamped(to: 1...5) }
}

struct RecommendationRowView: View {
    let recommendation: Recommendation
    @State private var isExpanded = false

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(alignment: .top, spacing: Spacing.sm) {
                    categoryIcon
                    VStack(alignment: .leading, spacing: 2) {
                        Text(recommendation.title)
                            .font(.titleSmall).fontWeight(.semibold).foregroundStyle(.textPrimary)
                        if isExpanded {
                            Text(recommendation.detail)
                                .font(.bodyMedium).foregroundStyle(.textSecondary)
                                .lineSpacing(3)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    Spacer()
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var categoryIcon: some View {
        ZStack {
            Circle().fill(categoryColor.opacity(0.15)).frame(width: 32, height: 32)
            Image(systemName: recommendation.category.icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(categoryColor)
        }
    }

    private var categoryColor: Color {
        switch recommendation.category {
        case .caffeine: return .scoreFair
        case .exercise: return .sleepTeal
        case .stress: return .sleepPurpleLight
        case .alcohol: return .scorePoor
        case .supplements: return .positive
        case .screenTime: return .warning
        case .schedule: return .sleepTealLight
        case .environment: return .stageDeep
        case .general: return .sleepPurple
        }
    }
}

struct InsightHistoryRow: View {
    let insight: SleepInsight

    var body: some View {
        GlassCard {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(insight.periodDescription)
                        .font(.titleSmall).foregroundStyle(.textPrimary)
                    Text(insight.summary)
                        .font(.bodyMedium).foregroundStyle(.textSecondary).lineLimit(2)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    trendBadge(insight.trend)
                    Text("\(insight.dataPointsAnalyzed) nights")
                        .font(.caption).foregroundStyle(.textTertiary)
                }
            }
        }
    }

    private func trendBadge(_ trend: ScoreTrend) -> some View {
        HStack(spacing: 3) {
            Image(systemName: trend.icon).font(.system(size: 9, weight: .bold))
            Text(trend.rawValue.capitalized).font(.caption).fontWeight(.medium)
        }
        .foregroundStyle(trendColor(trend))
    }

    private func trendColor(_ trend: ScoreTrend) -> Color {
        switch trend {
        case .improving: return .positive
        case .stable: return .textSecondary
        case .declining: return .scorePoor
        }
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
