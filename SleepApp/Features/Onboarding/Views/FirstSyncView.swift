import SwiftUI

struct FirstSyncView: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel
    @State private var checkmarkScale: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: Spacing.xxl) {
                indicator

                VStack(spacing: Spacing.sm) {
                    Text(viewModel.syncComplete ? "You're all set!" : "Loading your sleep data…")
                        .font(.displaySmall)
                        .fontWeight(.bold)
                        .foregroundStyle(.textPrimary)
                        .animation(.easeOut, value: viewModel.syncComplete)

                    if viewModel.syncComplete {
                        Group {
                            if viewModel.syncedNightsCount > 0 {
                                Text("Found \(viewModel.syncedNightsCount) night\(viewModel.syncedNightsCount == 1 ? "" : "s") of sleep data.")
                            } else {
                                Text("No existing sleep data found. Log tonight's sleep to get started.")
                            }
                        }
                        .font(.bodyLarge)
                        .foregroundStyle(.textSecondary)
                        .multilineTextAlignment(.center)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    } else {
                        Text("Importing the last 60 nights from Apple Health…")
                            .font(.bodyLarge)
                            .foregroundStyle(.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, Spacing.xl)
            }

            Spacer()

            if viewModel.syncComplete {
                PrimaryButton(title: "Let's Go", icon: "arrow.right") {
                    viewModel.complete()
                }
                .padding(.horizontal, Spacing.xl)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            Spacer(minLength: Spacing.xl)
        }
    }

    private var indicator: some View {
        ZStack {
            if viewModel.syncComplete {
                Circle()
                    .fill(Color.positive.opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: "checkmark")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(.positive)
                    .scaleEffect(checkmarkScale)
                    .onAppear {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
                            checkmarkScale = 1
                        }
                    }
            } else {
                LoadingRingView()
                    .frame(width: 80, height: 80)

                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.sleepPurpleLight)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: viewModel.syncComplete)
    }
}
