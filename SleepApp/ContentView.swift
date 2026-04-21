import SwiftUI

struct ContentView: View {
    @State private var selectedTab: AppTab = .dashboard
    @State private var showLogSheet = false
    @StateObject private var chatViewModel = SleepChatViewModel()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DashboardView(showLogSheet: $showLogSheet)
                    .tag(AppTab.dashboard)
                SleepHistoryView()
                    .tag(AppTab.history)
                InsightsView()
                    .tag(AppTab.insights)
                SettingsView()
                    .tag(AppTab.settings)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: selectedTab)

            SleepTabBar(selectedTab: $selectedTab, showLogSheet: $showLogSheet)
        }
        .sheet(isPresented: $showLogSheet) {
            DailyLogSheetView()
        }
        .background(Color.sleepBackground.ignoresSafeArea())
        .environmentObject(chatViewModel)
    }
}

enum AppTab: Int, CaseIterable {
    case dashboard, history, insights, settings

    var icon: String {
        switch self {
        case .dashboard: return "moon.stars.fill"
        case .history: return "chart.bar.fill"
        case .insights: return "sparkles"
        case .settings: return "gearshape.fill"
        }
    }

    var label: String {
        switch self {
        case .dashboard: return "Sleep"
        case .history: return "History"
        case .insights: return "Insights"
        case .settings: return "Settings"
        }
    }
}

struct SleepTabBar: View {
    @Binding var selectedTab: AppTab
    @Binding var showLogSheet: Bool

    var body: some View {
        HStack(spacing: 0) {
            tabButton(.dashboard)
            tabButton(.history)
            Spacer()
            logButton
            Spacer()
            tabButton(.insights)
            tabButton(.settings)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.sm)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(alignment: .top) {
                    Divider().overlay(Color.sleepBorder)
                }
                .ignoresSafeArea(edges: .bottom)
        }
        .sensoryFeedback(.selection, trigger: selectedTab)
    }

    private func tabButton(_ tab: AppTab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 22, weight: .medium))
                    .scaleEffect(selectedTab == tab ? 1.15 : 1.0)
                Text(tab.label)
                    .font(.labelSmall)
                    .fontWeight(selectedTab == tab ? .semibold : .regular)
            }
            .foregroundStyle(selectedTab == tab ? Color.sleepPurpleLight : Color.textTertiary)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
        .accessibilityLabel(tab.label)
    }

    private var logButton: some View {
        Button { showLogSheet = true } label: {
            ZStack {
                Circle()
                    .fill(Color.sleepPurple.opacity(0.18))
                    .frame(width: 72, height: 72)
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.sleepPurple, Color.sleepTeal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: Color.sleepPurple.opacity(0.55), radius: 18, y: 6)
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
        .offset(y: -16)
        .accessibilityLabel("Log today's sleep factors")
    }
}
