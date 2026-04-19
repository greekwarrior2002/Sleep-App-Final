import SwiftUI

struct GlassCard<Content: View>: View {
    let content: () -> Content
    var cornerRadius: CGFloat = Radius.lg
    var padding: CGFloat = Spacing.md
    var shadowRadius: CGFloat = 12

    init(
        cornerRadius: CGFloat = Radius.lg,
        padding: CGFloat = Spacing.md,
        shadowRadius: CGFloat = 12,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.shadowRadius = shadowRadius
        self.content = content
    }

    var body: some View {
        content()
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.sleepSurface)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(Color.sleepBorder, lineWidth: 1)
                    }
            }
            .shadow(color: .black.opacity(0.25), radius: shadowRadius, x: 0, y: 4)
    }
}

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat
    var padding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.sleepSurface)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(Color.sleepBorder, lineWidth: 1)
                    }
            }
            .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 4)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = Radius.lg, padding: CGFloat = Spacing.md) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, padding: padding))
    }
}

// Elevated card with slightly brighter surface
struct ElevatedCard<Content: View>: View {
    let content: () -> Content
    var cornerRadius: CGFloat = Radius.lg

    init(cornerRadius: CGFloat = Radius.lg, @ViewBuilder content: @escaping () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content
    }

    var body: some View {
        content()
            .padding(Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.sleepElevated)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(Color.sleepBorder, lineWidth: 1)
                    }
            }
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 2)
    }
}
