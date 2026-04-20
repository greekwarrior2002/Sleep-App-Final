import Foundation
import SwiftData
import Combine

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: String
    let content: String
    let timestamp: Date = Date()

    var isUser: Bool { role == "user" }
}

@MainActor
final class SleepChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isTyping = false
    @Published var error: String?
    @Published var hasAPIKey = false

    private var sleepRepo: SleepRepository?
    private var logRepo: DailyLogRepository?
    private let aiService = ClaudeAIService.shared
    private var sleepContext: String = ""

    func setup(context: ModelContext) {
        guard sleepRepo == nil else { return }
        sleepRepo = SleepRepository(context: context)
        logRepo = DailyLogRepository(context: context)
        hasAPIKey = KeychainService.shared.hasAPIKey
        loadContext()
    }

    private func loadContext() {
        guard let sleepRepo, let logRepo else { return }
        let sessions = (try? sleepRepo.fetchRecent(days: 30)) ?? []
        let logs = (try? logRepo.fetchRecent(days: 30)) ?? []
        sleepContext = aiService.buildSleepContext(sessions: sessions, logs: logs)

        if messages.isEmpty {
            messages.append(ChatMessage(
                role: "assistant",
                content: "Hi! I'm your sleep coach. Ask me anything about your sleep patterns, what might be affecting your rest, or how to improve your scores."
            ))
        }
    }

    func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty, !isTyping else { return }
        inputText = ""

        let userMsg = ChatMessage(role: "user", content: text)
        messages.append(userMsg)

        isTyping = true
        error = nil
        defer { isTyping = false }

        let history = messages.dropLast().map { (role: $0.role, content: $0.content) }

        do {
            let reply = try await aiService.sendChatMessage(
                history: Array(history),
                userMessage: text,
                sleepContext: sleepContext
            )
            messages.append(ChatMessage(role: "assistant", content: reply))
        } catch {
            self.error = error.localizedDescription
            messages.removeLast()
        }
    }

    func clearChat() {
        messages = []
        loadContext()
    }
}
