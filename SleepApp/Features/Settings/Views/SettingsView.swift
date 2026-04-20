import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sleepBackground.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.md) {
                        sleepGoalsSection
                        aiSection
                        notificationsSection
                        healthKitSection
                        iCloudSection
                        exportSection
                        appSection
                        resetSection
                        Spacer(minLength: 100)
                    }
                    .padding(Spacing.md)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task { viewModel.setup(context: context) }
        .sheet(isPresented: $viewModel.showExportSheet) {
            if let url = viewModel.exportURL {
                ShareSheet(items: [url])
            }
        }
    }

    private var exportSection: some View {
        SettingsSection(title: "Export Data", icon: "square.and.arrow.up.fill", iconColor: .sleepTealLight) {
            VStack(spacing: Spacing.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("CSV Spreadsheet").font(.bodyMedium).foregroundStyle(.textSecondary)
                        Text("All nights, scores & lifestyle logs").font(.caption).foregroundStyle(.textTertiary)
                    }
                    Spacer()
                    Button("Export") { Task { await viewModel.exportCSV() } }
                        .font(.labelLarge).foregroundStyle(.sleepTealLight)
                }
                Divider().overlay(Color.sleepBorder)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("PDF Report").font(.bodyMedium).foregroundStyle(.textSecondary)
                        Text("30-day formatted summary report").font(.caption).foregroundStyle(.textTertiary)
                    }
                    Spacer()
                    Button("Export") { Task { await viewModel.exportPDF() } }
                        .font(.labelLarge).foregroundStyle(.sleepTealLight)
                }
            }
        }
    }

    private var sleepGoalsSection: some View {
        SettingsSection(title: "Sleep Goals", icon: "moon.fill", iconColor: .sleepPurpleLight) {
            VStack(spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        Text("Sleep Goal").font(.bodyMedium).foregroundStyle(.textSecondary)
                        Spacer()
                        Text(String(format: "%.1fh", viewModel.sleepGoalHours))
                            .font(.titleSmall).fontWeight(.semibold).foregroundStyle(.sleepPurpleLight)
                    }
                    SleepSlider(value: $viewModel.sleepGoalHours, range: 5.0...10.0, step: 0.5, trackColor: .sleepPurple)
                }
                Divider().overlay(Color.sleepBorder)
                HStack {
                    Text("Bedtime").font(.bodyMedium).foregroundStyle(.textSecondary)
                    Spacer()
                    TimePicker(hour: $viewModel.bedtimeHour, minute: $viewModel.bedtimeMinute)
                }
                HStack {
                    Text("Wake Time").font(.bodyMedium).foregroundStyle(.textSecondary)
                    Spacer()
                    TimePicker(hour: $viewModel.wakeHour, minute: $viewModel.wakeMinute)
                }
            }
        }
    }

    private var aiSection: some View {
        SettingsSection(title: "Claude AI", icon: "sparkles", iconColor: .sleepPurpleLight) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("API Key").font(.bodyMedium).foregroundStyle(.textSecondary)
                        Text(viewModel.claudeAPIKey.isEmpty ? "Not configured" : viewModel.maskedAPIKey)
                            .font(.labelSmall)
                            .foregroundStyle(viewModel.claudeAPIKey.isEmpty ? .textTertiary : .positive)
                            .lineLimit(1)
                    }
                    Spacer()
                    if !viewModel.claudeAPIKey.isEmpty {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.positive)
                    }
                }

                HStack(spacing: Spacing.xs) {
                    ZStack {
                        RoundedRectangle(cornerRadius: Radius.sm)
                            .fill(Color.sleepElevated)
                            .overlay {
                                RoundedRectangle(cornerRadius: Radius.sm)
                                    .strokeBorder(Color.sleepBorder, lineWidth: 1)
                            }
                        if viewModel.isAPIKeyVisible {
                            TextField("sk-ant-...", text: $viewModel.claudeAPIKey)
                                .font(.bodyMedium).foregroundStyle(.textPrimary)
                                .autocorrectionDisabled().textInputAutocapitalization(.never)
                                .padding(.horizontal, Spacing.sm)
                        } else {
                            SecureField("sk-ant-...", text: $viewModel.claudeAPIKey)
                                .font(.bodyMedium).foregroundStyle(.textPrimary)
                                .padding(.horizontal, Spacing.sm)
                        }
                    }
                    .frame(height: 44)

                    Button { viewModel.isAPIKeyVisible.toggle() } label: {
                        Image(systemName: viewModel.isAPIKeyVisible ? "eye.slash" : "eye")
                            .foregroundStyle(.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 36, height: 44)
                }

                PrimaryButton(
                    title: viewModel.successMessage ?? "Save Key",
                    icon: viewModel.successMessage != nil ? "checkmark" : nil,
                    isDisabled: viewModel.claudeAPIKey.isEmpty
                ) {
                    viewModel.saveAPIKey()
                }
                .frame(height: 44)

                Text("Get a key at console.anthropic.com. Stored securely in your device's Keychain.")
                    .font(.caption).foregroundStyle(.textTertiary)
            }
        }
    }

    private var notificationsSection: some View {
        SettingsSection(title: "Notifications", icon: "bell.fill", iconColor: .sleepTeal) {
            VStack(spacing: Spacing.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Bedtime Reminder").font(.bodyMedium).foregroundStyle(.textSecondary)
                        if viewModel.bedtimeReminderEnabled {
                            TimePicker(hour: $viewModel.bedtimeReminderHour, minute: $viewModel.bedtimeReminderMinute)
                                .scaleEffect(0.85, anchor: .leading)
                        }
                    }
                    Spacer()
                    Toggle("", isOn: $viewModel.bedtimeReminderEnabled)
                        .tint(.sleepTeal)
                        .onChange(of: viewModel.bedtimeReminderEnabled) { _, _ in viewModel.updateNotifications() }
                }
                Divider().overlay(Color.sleepBorder)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Morning Check-in").font(.bodyMedium).foregroundStyle(.textSecondary)
                        if viewModel.morningCheckinEnabled {
                            TimePicker(hour: $viewModel.morningCheckinHour, minute: $viewModel.morningCheckinMinute)
                                .scaleEffect(0.85, anchor: .leading)
                        }
                    }
                    Spacer()
                    Toggle("", isOn: $viewModel.morningCheckinEnabled)
                        .tint(.sleepTeal)
                        .onChange(of: viewModel.morningCheckinEnabled) { _, _ in viewModel.updateNotifications() }
                }
            }
        }
    }

    private var healthKitSection: some View {
        SettingsSection(title: "Apple Health", icon: "heart.fill", iconColor: .scorePoor) {
            HStack {
                Text("Manage HealthKit permissions")
                    .font(.bodyMedium).foregroundStyle(.textSecondary)
                Spacer()
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.labelLarge).foregroundStyle(.sleepPurpleLight)
            }
        }
    }

    private var iCloudSection: some View {
        SettingsSection(title: "iCloud Sync", icon: "icloud.fill", iconColor: .sleepTealLight) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sync across devices").font(.bodyMedium).foregroundStyle(.textSecondary)
                    Text(iCloudStatusText).font(.caption).foregroundStyle(.textTertiary)
                }
                Spacer()
                Image(systemName: iCloudStatusIcon)
                    .foregroundStyle(iCloudStatusColor)
            }
        }
    }

    private var iCloudStatusText: String {
        FileManager.default.ubiquityIdentityToken != nil
            ? "Signed in to iCloud — data syncing automatically"
            : "Sign in to iCloud in device Settings to enable sync"
    }

    private var iCloudStatusIcon: String {
        FileManager.default.ubiquityIdentityToken != nil ? "checkmark.circle.fill" : "xmark.circle"
    }

    private var iCloudStatusColor: Color {
        FileManager.default.ubiquityIdentityToken != nil ? .positive : .textTertiary
    }

    private var appSection: some View {
        SettingsSection(title: "App", icon: "info.circle.fill", iconColor: .textSecondary) {
            VStack(spacing: Spacing.sm) {
                HStack {
                    Text("Version").font(.bodyMedium).foregroundStyle(.textSecondary)
                    Spacer()
                    Text(viewModel.appVersion).font(.bodyMedium).foregroundStyle(.textTertiary)
                }
                Divider().overlay(Color.sleepBorder)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Data Retention").font(.bodyMedium).foregroundStyle(.textSecondary)
                        Text("Auto-removes data older than 180 days")
                            .font(.caption).foregroundStyle(.textTertiary)
                    }
                    Spacer()
                    Button("Clean Now") {
                        Task { await viewModel.runDataCleanup() }
                    }
                    .font(.labelLarge).foregroundStyle(.sleepPurpleLight)
                }
            }
        }
    }

    private var resetSection: some View {
        GlassCard {
            DestructiveButton(title: "Reset All Data") {
                viewModel.showResetConfirmation = true
            }
        }
        .confirmationDialog(
            "Reset All Data",
            isPresented: $viewModel.showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset Everything", role: .destructive) {
                Task { await viewModel.resetAllData() }
            }
        } message: {
            Text("This will delete all sleep sessions, daily logs, insights, and your API key. This cannot be undone.")
        }
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: () -> Content

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(iconColor)
                        .frame(width: 18)
                    Text(title)
                        .font(.titleSmall).fontWeight(.semibold).foregroundStyle(.textPrimary)
                }
                Divider().overlay(Color.sleepBorder)
                content()
            }
        }
    }
}
