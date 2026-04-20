import SwiftUI

struct SleepSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double = 1
    var trackColor: Color = .sleepPurple
    var label: String? = nil

    var body: some View {
        VStack(spacing: Spacing.xs) {
            if let label {
                HStack {
                    Text(label)
                        .font(.labelLarge)
                        .foregroundStyle(Color.textSecondary)
                    Spacer()
                    Text(formattedValue)
                        .font(.titleSmall)
                        .fontWeight(.semibold)
                        .foregroundStyle(trackColor)
                        .monoDigits()
                }
            }

            Slider(value: $value, in: range, step: step)
                .tint(trackColor)
        }
    }

    private var formattedValue: String {
        if step >= 1 {
            return "\(Int(value))"
        }
        return String(format: "%.1f", value)
    }
}

struct StressSlider: View {
    @Binding var value: Int
    private let emojis = ["😌", "🙂", "😐", "😟", "😰"]
    private let labels = ["Very Low", "Low", "Moderate", "High", "Very High"]

    var body: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                ForEach(1...5, id: \.self) { level in
                    VStack(spacing: 4) {
                        Text(emojis[level - 1])
                            .font(.system(size: value == level ? 28 : 20))
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: value)
                        Rectangle()
                            .fill(value == level ? Color.sleepPurple : Color.sleepElevated)
                            .frame(height: 4)
                            .cornerRadius(2)
                    }
                    .frame(maxWidth: .infinity)
                    .onTapGesture { value = level }
                }
            }

            HStack {
                Text("Very Calm")
                    .font(.caption)
                    .foregroundStyle(Color.textTertiary)
                Spacer()
                Text("Very Stressed")
                    .font(.caption)
                    .foregroundStyle(Color.textTertiary)
            }
        }
    }
}

struct IntensityPicker: View {
    @Binding var value: Int
    let options = [(1, "Light"), (2, "Moderate"), (3, "Intense")]

    var body: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(options, id: \.0) { intensity, label in
                Button {
                    value = intensity
                } label: {
                    Text(label)
                        .font(.labelLarge)
                        .foregroundStyle(value == intensity ? Color.white : Color.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.xs)
                        .background {
                            RoundedRectangle(cornerRadius: Radius.sm)
                                .fill(value == intensity ? Color.sleepPurple : Color.sleepElevated)
                        }
                }
                .buttonStyle(.plain)
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: value)
            }
        }
    }
}
