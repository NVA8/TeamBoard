import Foundation

public protocol ObserveChatMessagesUseCase: Sendable {
    func execute(channelId: Identifier<ChatChannel>) -> AsyncThrowingStream<[ChatMessage], Error>
}

public protocol SendChatMessageUseCase: Sendable {
    func execute(_ message: ChatMessage) async throws
}

public struct DefaultObserveChatMessagesUseCase: ObserveChatMessagesUseCase {
    private let repository: ChatRepository

    public init(repository: ChatRepository) {
        self.repository = repository
    }

    public func execute(channelId: Identifier<ChatChannel>) -> AsyncThrowingStream<[ChatMessage], Error> {
        repository.observeMessages(channelId: channelId)
    }
}

public struct DefaultSendChatMessageUseCase: SendChatMessageUseCase {
    private let repository: ChatRepository

    public init(repository: ChatRepository) {
        self.repository = repository
    }

    public func execute(_ message: ChatMessage) async throws {
        try await repository.sendMessage(message)
    }
}

