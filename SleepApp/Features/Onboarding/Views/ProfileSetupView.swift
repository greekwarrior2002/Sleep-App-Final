import SwiftUI

struct ProfileSetupView: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel
    @State private var appeared = false

    private let goalOptions: [Double] = [6.0, 6.5, 7.0, 7.5, 8.0, 8.5, 9.0]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: Spacing.xxl) {
                header
                formSection
            }
            .padding(.horizontal, Spacing.xl)

            Spacer()

            PrimaryButton(title: "Continue") {
                Task { await viewModel.saveProfileAndSync() }
            }
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
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 40))
                .foregroundStyle(.sleepPurpleLight)

            Text("Your Sleep Profile")
                .font(.displaySmall)
                .fontWeight(.bold)
                .foregroundStyle(.textPrimary)

            Text("Set your sleep goals so Slumber can score and personalize insights for you.")
                .font(.bodyLarge)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var formSection: some View {
        VStack(spacing: Spacing.md) {
            GlassCard {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Text("Sleep Goal")
                            .font(.titleSmall)
                            .foregroundStyle(.textPrimary)
                        Spacer()
                        Text(String(format: "%.1f hours", viewModel.sleepGoalHours))
                            .font(.titleSmall)
                            .fontWeight(.semibold)
                            .foregroundStyle(.sleepPurpleLight)
                            .monoDigits()
                    }

                    HStack(spacing: Spacing.xs) {
                        ForEach(goalOptions, id: \.self) { goal in
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    viewModel.sleepGoalHours = goal
                                }
                            } label: {
                                Text(String(format: goal == floor(goal) ? "%.0fh" : "%.1fh", goal))
                                    .font(.labelLarge)
                                    .foregroundStyle(viewModel.sleepGoalHours == goal ? .white : Color.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, Spacing.xs)
                                    .background {
                                        RoundedRectangle(cornerRadius: Radius.sm)
                                            .fill(viewModel.sleepGoalHours == goal ? Color.sleepPurple : Color.sleepElevated)
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            GlassCard {
                VStack(spacing: Spacing.sm) {
                    HStack {
                        Image(systemName: "bed.double.fill")
                            .foregroundStyle(.sleepPurpleLight)
                        Text("Bedtime")
                            .font(.titleSmall)
                            .foregroundStyle(.textPrimary)
                        Spacer()
                        TimePicker(hour: $viewModel.bedtimeHour, minute: $viewModel.bedtimeMinute)
                    }

                    Divider().overlay(Color.sleepBorder)

                    HStack {
                        Image(systemName: "sun.max.fill")
                            .foregroundStyle(.scoreFair)
                        Text("Wake Time")
                            .font(.titleSmall)
                            .foregroundStyle(.textPrimary)
                        Spacer()
                        TimePicker(hour: $viewModel.wakeHour, minute: $viewModel.wakeMinute)
                    }
                }
            }
        }
    }
}

struct TimePicker: View {
    @Binding var hour: Int
    @Binding var minute: Int

    private var dateBinding: Binding<Date> {
        Binding(
            get: {
                var components = DateComponents()
                components.hour = hour
                components.minute = minute
                return Calendar.current.date(from: components) ?? Date()
            },
            set: { date in
                hour = Calendar.current.component(.hour, from: date)
                minute = Calendar.current.component(.minute, from: date)
            }
        )
    }

    var body: some View {
        DatePicker("", selection: dateBinding, displayedComponents: .hourAndMinute)
            .labelsHidden()
            .colorScheme(.dark)
            .tint(.sleepPurpleLight)
    }
}
