import SwiftUI

struct ContentView: View {
    @State private var selectedTab: AppTab = .dashboard
    @State private var showLogSheet = false
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
                SleepChatView()
                    .tag(AppTab.chat)
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
    }
}

enum AppTab: Int, CaseIterable {
    case dashboard, history, insights, chat, settings

    var icon: String {
        switch self {
        case .dashboard: return "moon.stars.fill"
        case .history: return "chart.bar.fill"
        case .insights: return "sparkles"
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .settings: return "gearshape.fill"
        }
    }

    var label: String {
        switch self {
        case .dashboard: return "Sleep"
        case .history: return "History"
        case .insights: return "Insights"
        case .chat: return "Coach"
        case .settings: return "Settings"
        }
    }
}

struct SleepTabBar: View {
    @Binding var selectedTab: AppTab
    @Binding var showLogSheet: Bool

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.rawValue) { tab in
                if tab == .insights {
                    tabButton(tab)
                    Spacer()
                    logButton
                    Spacer()
                } else {
                    tabButton(tab)
                }
            }
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
    }

    private func tabButton(_ tab: AppTab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 22, weight: .medium))
                Text(tab.label)
                    .font(.labelSmall)
            }
            .foregroundStyle(selectedTab == tab ? Color.sleepPurpleLight : Color.textTertiary)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
    }

    private var logButton: some View {
        Button { showLogSheet = true } label: {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.sleepPurple, Color.sleepTeal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                    .shadow(color: Color.sleepPurple.opacity(0.4), radius: 12, y: 4)
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
        .offset(y: -10)
    }
}
