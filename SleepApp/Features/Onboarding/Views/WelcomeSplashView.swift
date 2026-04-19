import SwiftUI

struct WelcomeSplashView: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel
    @State private var moonAppeared = false
    @State private var titleAppeared = false
    @State private var buttonAppeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            moonIcon
                .padding(.bottom, Spacing.xl)

            VStack(spacing: Spacing.sm) {
                Text("Slumber")
                    .font(.displayMedium)
                    .fontWeight(.bold)
                    .foregroundStyle(.textPrimary)

                Text("Sleep smarter. Wake better.")
                    .font(.titleMedium)
                    .foregroundStyle(.textSecondary)
            }
            .opacity(titleAppeared ? 1 : 0)
            .offset(y: titleAppeared ? 0 : 20)

            Spacer()

            featureList
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xxl)

            PrimaryButton(title: "Get Started", icon: "arrow.right") {
                viewModel.advance()
            }
            .padding(.horizontal, Spacing.xl)
            .opacity(buttonAppeared ? 1 : 0)
            .offset(y: buttonAppeared ? 0 : 20)

            Spacer(minLength: Spacing.xl)
        }
        .onAppear { runAnimations() }
    }

    private var moonIcon: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.sleepPurple.opacity(0.3), Color.clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)

            Image(systemName: "moon.stars.fill")
                .font(.system(size: 72))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.sleepPurpleLight, Color.sleepTealLight],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .rotationEffect(.degrees(moonAppeared ? 0 : -20))
                .scaleEffect(moonAppeared ? 1 : 0.7)
                .opacity(moonAppeared ? 1 : 0)
        }
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            featureRow(icon: "heart.fill", color: .scorePoor, text: "Apple Health integration")
            featureRow(icon: "chart.bar.fill", color: .sleepTeal, text: "Sleep trends & history")
            featureRow(icon: "sparkles", color: .sleepPurple, text: "AI-powered insights")
            featureRow(icon: "note.text", color: .scoreFair, text: "Lifestyle logging")
        }
        .opacity(titleAppeared ? 1 : 0)
    }

    private func featureRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(color)
            }
            Text(text)
                .font(.bodyLarge)
                .foregroundStyle(.textSecondary)
        }
    }

    private func runAnimations() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            moonAppeared = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
            titleAppeared = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.7)) {
            buttonAppeared = true
        }
    }
}
