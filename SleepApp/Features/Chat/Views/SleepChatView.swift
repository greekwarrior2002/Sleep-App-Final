import SwiftUI
import SwiftData

struct SleepChatView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject var viewModel: SleepChatViewModel
    @FocusState private var inputFocused: Bool

    private var canSend: Bool {
        !viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty
            && !viewModel.isTyping
            && viewModel.hasAPIKey
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sleepBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    if viewModel.hasAPIKey {
                        messageList
                        if let error = viewModel.error { errorBar(error) }
                        inputBar
                    } else {
                        noAPIKeyView
                    }
                }
            }
            .navigationTitle("Sleep Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") { viewModel.clearChat() }
                        .font(.labelLarge).foregroundStyle(.textTertiary)
                        .disabled(viewModel.messages.count <= 1)
                }
            }
        }
        .task {
            viewModel.setup(context: context)
        }
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: Spacing.sm) {
                    ForEach(viewModel.messages) { message in
                        ChatBubbleView(message: message)
                            .id(message.id)
                    }
                    if viewModel.isTyping {
                        typingIndicator
                    }
                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(Spacing.md)
                .padding(.bottom, Spacing.sm)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: viewModel.messages.count) { _, _ in
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            .onChange(of: viewModel.isTyping) { _, typing in
                if typing {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Typing Indicator

    private var typingIndicator: some View {
        HStack(alignment: .bottom, spacing: Spacing.xs) {
            assistantAvatar
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    AnimatedDot(delay: Double(i) * 0.15)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background { RoundedRectangle(cornerRadius: 18).fill(Color.sleepSurface) }
            Spacer()
        }
        .id("typing")
    }

    private var assistantAvatar: some View {
        ZStack {
            Circle().fill(Color.sleepPurpleDim).frame(width: 28, height: 28)
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.sleepPurpleLight)
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: Spacing.sm) {
            TextField("Ask about your sleep…", text: $viewModel.inputText, axis: .vertical)
                .font(.bodyMedium).foregroundStyle(.textPrimary)
                .lineLimit(1...4)
                .focused($inputFocused)
                .padding(.horizontal, Spacing.sm).padding(.vertical, 10)
                .background {
                    RoundedRectangle(cornerRadius: Radius.xl)
                        .fill(Color.sleepSurface)
                        .overlay {
                            RoundedRectangle(cornerRadius: Radius.xl)
                                .strokeBorder(Color.sleepBorder, lineWidth: 1)
                        }
                }
                .onSubmit {
                    Task { await viewModel.sendMessage() }
                }

            Button {
                Task { await viewModel.sendMessage() }
            } label: {
                ZStack {
                    Circle().fill(
                        LinearGradient(
                            colors: [.sleepPurple, .sleepTeal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing)
                    )
                    Image(systemName: "arrow.up")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
            .opacity(canSend ? 1 : 0.4)
            .scaleEffect(canSend ? 1.0 : 0.88)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: canSend)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background {
            Rectangle().fill(.ultraThinMaterial)
                .overlay(alignment: .top) { Divider().overlay(Color.sleepBorder) }
                .ignoresSafeArea(edges: .bottom)
        }
    }

    // MARK: - No API Key State

    private var noAPIKeyView: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
            VStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.sleepPurpleDim)
                        .frame(width: 72, height: 72)
                    Image(systemName: "key.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.sleepPurpleLight)
                }
                VStack(spacing: Spacing.xs) {
                    Text("Claude API Key Required")
                        .font(.titleMedium)
                        .foregroundStyle(.textPrimary)
                        .multilineTextAlignment(.center)
                    Text("Your Sleep Coach uses Claude AI to give you personalized guidance based on your sleep data.")
                        .font(.bodyMedium)
                        .foregroundStyle(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.lg)
                }
            }
            .glassCard()
            .padding(.horizontal, Spacing.md)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error Bar

    private func errorBar(_ message: String) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.warning)
                .font(.system(size: 12))
            Text(message)
                .font(.caption)
                .foregroundStyle(.textSecondary)
                .lineLimit(2)
            Spacer()
            Button {
                viewModel.error = nil
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.xs)
        .background(Color.sleepSurface)
    }
}

// MARK: - Animated Dot

private struct AnimatedDot: View {
    let delay: Double
    @State private var scale: CGFloat = 0.5

    var body: some View {
        Circle()
            .fill(Color.sleepPurpleLight)
            .frame(width: 6, height: 6)
            .scaleEffect(scale)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 0.5)
                        .repeatForever(autoreverses: true)
                        .delay(delay)
                ) {
                    scale = 1.0
                }
            }
    }
}

// MARK: - Chat Bubble

struct ChatBubbleView: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: Spacing.xs) {
            if message.isUser { Spacer(minLength: 60) }
            if !message.isUser { avatar }

            Text(message.content)
                .font(.bodyMedium)
                .foregroundStyle(message.isUser ? .white : .textPrimary)
                .lineSpacing(3)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(message.isUser
                            ? LinearGradient(
                                colors: [.sleepPurple, Color(hex: "5B21B6")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing)
                            : LinearGradient(
                                colors: [Color.sleepSurface, Color.sleepSurface],
                                startPoint: .top,
                                endPoint: .bottom))
                }

            if !message.isUser { Spacer(minLength: 60) }
        }
    }

    private var avatar: some View {
        ZStack {
            Circle().fill(Color.sleepPurpleDim).frame(width: 28, height: 28)
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.sleepPurpleLight)
        }
    }
}
