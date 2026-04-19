import SwiftUI

struct LoadingRingView: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.sleepElevated, lineWidth: 4)

            Circle()
                .trim(from: 0, to: 0.25)
                .stroke(
                    LinearGradient(
                        colors: [Color.sleepPurple, Color.sleepTeal],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(
                    .linear(duration: 1.0).repeatForever(autoreverses: false),
                    value: isAnimating
                )
        }
        .onAppear { isAnimating = true }
    }
}

struct ShimmerView: View {
    @State private var phase: CGFloat = -1

    var body: some View {
        GeometryReader { geometry in
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: Color.white.opacity(0.06), location: 0.5),
                    .init(color: .clear, location: 1)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: geometry.size.width * 3)
            .offset(x: phase * geometry.size.width * 3)
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
        }
        .clipped()
    }
}

extension View {
    func shimmer(isActive: Bool = true) -> some View {
        overlay {
            if isActive {
                ShimmerView()
                    .cornerRadius(Radius.md)
            }
        }
    }

    func skeletonLoading(isLoading: Bool) -> some View {
        redacted(reason: isLoading ? .placeholder : [])
            .shimmer(isActive: isLoading)
    }
}

struct SectionHeaderView: View {
    let title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.titleSmall)
                .fontWeight(.semibold)
                .foregroundStyle(.textPrimary)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.labelLarge)
                    .foregroundStyle(.sleepPurpleLight)
            }
        }
    }
}
