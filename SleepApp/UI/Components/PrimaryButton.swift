import SwiftUI

struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.85)
                } else {
                    if let icon {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text(title)
                        .font(.titleSmall)
                        .fontWeight(.semibold)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background {
                RoundedRectangle(cornerRadius: Radius.md)
                    .fill(
                        isDisabled
                        ? AnyShapeStyle(Color.sleepPurple.opacity(0.4))
                        : AnyShapeStyle(LinearGradient(
                            colors: [Color.sleepPurple, Color(hex: "5B21B6")],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                    )
            }
            .shadow(
                color: isDisabled ? .clear : Color.sleepPurple.opacity(0.4),
                radius: 12,
                y: 4
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled || isLoading)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isLoading)
    }
}

struct SecondaryButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .medium))
                }
                Text(title)
                    .font(.titleSmall)
            }
            .foregroundStyle(.sleepPurpleLight)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background {
                RoundedRectangle(cornerRadius: Radius.md)
                    .strokeBorder(Color.sleepPurple.opacity(0.5), lineWidth: 1.5)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.md)
                            .fill(Color.sleepPurpleDim)
                    )
            }
        }
        .buttonStyle(.plain)
    }
}

struct DestructiveButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(role: .destructive, action: action) {
            Text(title)
                .font(.titleSmall)
                .foregroundStyle(.destructive)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background {
                    RoundedRectangle(cornerRadius: Radius.md)
                        .strokeBorder(Color.destructive.opacity(0.4), lineWidth: 1.5)
                        .background(
                            RoundedRectangle(cornerRadius: Radius.md)
                                .fill(Color.destructive.opacity(0.1))
                        )
                }
        }
        .buttonStyle(.plain)
    }
}
