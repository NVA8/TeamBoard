import Foundation
import _Concurrency

#if !canImport(FirebaseFirestore)

actor InMemoryChatRepository: ChatRepository {
    private var messagesStorage: [Identifier<ChatChannel>: [ChatMessage]] = [:]
    private var continuations: [Identifier<ChatChannel>: [UUID: AsyncThrowingStream<[ChatMessage], Error>.Continuation]] = [:]

    init() {
        let general = Identifier<ChatChannel>("general")
        let welcomeMessage = ChatMessage(
            id: Identifier("welcome-message"),
            channelId: general,
            authorId: Identifier<TeamMember>("owner"),
            body: "Добро пожаловать в TeamBoard! Обсуждайте задачи и превращайте сообщения в действия.",
            createdAt: .now.addingTimeInterval(-3_600),
            isSystemMessage: true
        )
        messagesStorage[general] = [welcomeMessage]
    }

    nonisolated func observeMessages(channelId: Identifier<ChatChannel>) -> AsyncThrowingStream<[ChatMessage], Error> {
        AsyncThrowingStream<[ChatMessage], Error> { continuation in
            let token = UUID()
            _Concurrency.Task { await registerContinuation(id: token, channelId: channelId, continuation: continuation) }
            continuation.onTermination = { _ in
                _Concurrency.Task { await self.removeContinuation(id: token, channelId: channelId) }
            }
        }
    }

    func sendMessage(_ message: ChatMessage) async throws {
        var messages = messagesStorage[message.channelId, default: []]
        messages.append(message)
        messages.sort { $0.createdAt < $1.createdAt }
        messagesStorage[message.channelId] = messages
        await notify(channelId: message.channelId)
    }

    func createChannel(_ channel: ChatChannel) async throws {
        messagesStorage[channel.id] = []
    }

    // MARK: - Helpers

    private func registerContinuation(
        id: UUID,
        channelId: Identifier<ChatChannel>,
        continuation: AsyncThrowingStream<[ChatMessage], Error>.Continuation
    ) {
        var channelContinuations = continuations[channelId, default: [:]]
        channelContinuations[id] = continuation
        continuations[channelId] = channelContinuations
        continuation.yield(messagesStorage[channelId, default: []])
    }

    private func removeContinuation(id: UUID, channelId: Identifier<ChatChannel>) {
        var channelContinuations = continuations[channelId, default: [:]]
        channelContinuations.removeValue(forKey: id)
        continuations[channelId] = channelContinuations
    }

    private func notify(channelId: Identifier<ChatChannel>) async {
        let messages = messagesStorage[channelId, default: []]
        let channelContinuations = continuations[channelId, default: [:]]
        channelContinuations.values.forEach { $0.yield(messages) }
    }
}

#endif
