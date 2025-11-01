import Foundation

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var channels: [ChatChannel] = []
    @Published var selectedChannel: ChatChannel?
    @Published var messages: [ChatMessage] = []
    @Published var inputText = ""

    private let environment: AppEnvironment
    private var streamTask: _Concurrency.Task<Void, Never>?

    init(environment: AppEnvironment) {
        self.environment = environment
        loadStubChannels()
    }

    func loadStubChannels() {
        channels = [
            ChatChannel(title: "Общий чат", participantIds: []),
            ChatChannel(title: "Design Team", participantIds: []),
            ChatChannel(title: "Dev Updates", participantIds: [])
        ]
        selectedChannel = channels.first
        observeMessages()
    }

    func observeMessages() {
        streamTask?.cancel()
        guard let channel = selectedChannel else { return }
        streamTask = _Concurrency.Task {
            do {
                for try await messages in environment.observeChatMessagesUseCase.execute(channelId: channel.id) {
                    await MainActor.run {
                        self.messages = messages
                    }
                }
            } catch {
                // handle gracefully
            }
        }
    }

    func sendMessage() {
        guard let channel = selectedChannel else { return }
        let message = ChatMessage(
            channelId: channel.id,
            authorId: Identifier<TeamMember>("me"),
            body: inputText
        )
        _Concurrency.Task {
            try? await environment.sendChatMessageUseCase.execute(message)
            await MainActor.run {
                inputText = ""
            }
        }
    }
}
