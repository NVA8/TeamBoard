import Foundation

public protocol ChatRepository: Sendable {
    func observeMessages(channelId: Identifier<ChatChannel>) -> AsyncThrowingStream<[ChatMessage], Error>
    func sendMessage(_ message: ChatMessage) async throws
    func createChannel(_ channel: ChatChannel) async throws
}

