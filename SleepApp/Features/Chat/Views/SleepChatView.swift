import SwiftUI
import SwiftData

struct SleepChatView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = SleepChatViewModel()
    @FocusState private var inputFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sleepBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    if !viewModel.hasAPIKey { apiKeyBanner }
                    messageList
                    if let error = viewModel.error { errorBar(error) }
                    inputBar
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

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: Spacing.sm) {
                    ForEach(viewModel.messages) { message in
                        ChatBubbleView(message: message)
                            .id(message.id)
                    }
                    if viewModel.isTyping { typingIndicator }
                }
                .padding(Spacing.md)
                .padding(.bottom, Spacing.sm)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                withAnimation { proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom) }
            }
            .onChange(of: viewModel.isTyping) { _, typing in
                if typing { withAnimation { proxy.scrollTo("typing", anchor: .bottom) } }
            }
        }
    }

    private var typingIndicator: some View {
        HStack(alignment: .bottom, spacing: Spacing.xs) {
            assistantAvatar
            HStack(spacing: 4) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(Color.sleepPurpleLight)
                        .frame(width: 6, height: 6)
                        .scaleEffect(viewModel.isTyping ? 1 : 0.5)
                        .animation(.easeInOut(duration: 0.5).repeatForever().delay(Double(i) * 0.15), value: viewModel.isTyping)
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
                        .overlay { RoundedRectangle(cornerRadius: Radius.xl).strokeBorder(Color.sleepBorder, lineWidth: 1) }
                }
                .onSubmit { Task { await viewModel.sendMessage() } }

            Button {
                Task { await viewModel.sendMessage() }
            } label: {
                ZStack {
                    Circle().fill(
                        LinearGradient(colors: [.sleepPurple, .sleepTeal], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    Image(systemName: "arrow.up")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isTyping || !viewModel.hasAPIKey)
            .opacity(viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty || !viewModel.hasAPIKey ? 0.4 : 1)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background {
            Rectangle().fill(.ultraThinMaterial)
                .overlay(alignment: .top) { Divider().overlay(Color.sleepBorder) }
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private var apiKeyBanner: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "key.fill").foregroundStyle(.sleepPurpleLight).font(.system(size: 13))
            Text("Add your Claude API key in Settings to enable the chat.")
                .font(.caption).foregroundStyle(.textSecondary)
        }
        .padding(Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.sleepSurface)
    }

    private func errorBar(_ message: String) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.warning).font(.system(size: 12))
            Text(message).font(.caption).foregroundStyle(.textSecondary).lineLimit(2)
        }
        .padding(.horizontal, Spacing.md).padding(.vertical, Spacing.xs)
        .background(Color.sleepSurface)
    }
}

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
                            ? LinearGradient(colors: [.sleepPurple, Color(hex: "5B21B6")], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color.sleepSurface, Color.sleepSurface], startPoint: .top, endPoint: .bottom))
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
