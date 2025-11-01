import Foundation

public struct ChatMessage: Identifiable, Codable, Equatable, Sendable {
    public let id: Identifier<ChatMessage>
    public var channelId: Identifier<ChatChannel>
    public var authorId: Identifier<TeamMember>
    public var body: String
    public var attachments: [TaskAttachment]
    public var createdAt: Date
    public var isSystemMessage: Bool
    public var voiceNoteURL: URL?
    public var voiceDuration: TimeInterval?
    public var voiceTranscription: String?

    public init(
        id: Identifier<ChatMessage> = Identifier(),
        channelId: Identifier<ChatChannel>,
        authorId: Identifier<TeamMember>,
        body: String,
        attachments: [TaskAttachment] = [],
        createdAt: Date = .now,
        isSystemMessage: Bool = false,
        voiceNoteURL: URL? = nil,
        voiceDuration: TimeInterval? = nil,
        voiceTranscription: String? = nil
    ) {
        self.id = id
        self.channelId = channelId
        self.authorId = authorId
        self.body = body
        self.attachments = attachments
        self.createdAt = createdAt
        self.isSystemMessage = isSystemMessage
        self.voiceNoteURL = voiceNoteURL
        self.voiceDuration = voiceDuration
        self.voiceTranscription = voiceTranscription
    }
}

public struct ChatChannel: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: Identifier<ChatChannel>
    public var title: String
    public var participantIds: [Identifier<TeamMember>]
    public var linkedBoardId: Identifier<Board>?
    public var createdAt: Date

    public init(
        id: Identifier<ChatChannel> = Identifier(),
        title: String,
        participantIds: [Identifier<TeamMember>],
        linkedBoardId: Identifier<Board>? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.participantIds = participantIds
        self.linkedBoardId = linkedBoardId
        self.createdAt = createdAt
    }
}
