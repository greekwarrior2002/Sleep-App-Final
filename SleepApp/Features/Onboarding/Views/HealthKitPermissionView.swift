import SwiftUI

struct HealthKitPermissionView: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel
    @State private var appeared = false

    private let permissions: [(icon: String, color: Color, title: String, desc: String)] = [
        ("moon.zzz.fill", Color.sleepPurpleLight, "Sleep Analysis", "Sleep stages, duration, and efficiency"),
        ("heart.fill", Color.scorePoor, "Heart Rate", "Resting HR during sleep windows"),
        ("waveform", Color.positive, "HRV", "Heart rate variability for recovery tracking"),
        ("lungs.fill", Color.sleepTeal, "Respiratory Rate", "Breathing patterns during sleep")
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: Spacing.xl) {
                header
                permissionsList
            }
            .padding(.horizontal, Spacing.xl)

            Spacer()

            footerButtons
                .padding(.horizontal, Spacing.xl)

            Spacer(minLength: Spacing.xl)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 30)
        .onAppear {
            withAnimation(.easeOut(duration: 0.45).delay(0.1)) { appeared = true }
        }
    }

    private var header: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(Color.scorePoor.opacity(0.15))
                    .frame(width: 72, height: 72)
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.scorePoor)
            }

            Text("Connect Apple Health")
                .font(.displaySmall)
                .fontWeight(.bold)
                .foregroundStyle(.textPrimary)

            Text("Slumber reads your sleep and health data to build your personalized sleep profile. Your data stays on your device.")
                .font(.bodyLarge)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
    }

    private var permissionsList: some View {
        VStack(spacing: Spacing.xs) {
            ForEach(permissions, id: \.title) { perm in
                HStack(spacing: Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(perm.color.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: perm.icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(perm.color)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(perm.title)
                            .font(.titleSmall)
                            .foregroundStyle(.textPrimary)
                        Text(perm.desc)
                            .font(.bodyMedium)
                            .foregroundStyle(.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(perm.color.opacity(0.6))
                }
                .glassCard()
            }
        }
    }

    private var footerButtons: some View {
        VStack(spacing: Spacing.sm) {
            PrimaryButton(title: "Grant Access") {
                Task { await viewModel.requestHealthKit() }
            }

            Button("Skip for now") {
                viewModel.healthKitDenied = true
                viewModel.advance()
            }
            .font(.bodyMedium)
            .foregroundStyle(.textTertiary)
        }
    }
}
