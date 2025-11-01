import Foundation

public struct TaskComment: Identifiable, Codable, Equatable, Sendable {
    public let id: Identifier<TaskComment>
    public var authorId: Identifier<TeamMember>
    public var message: String
    public var createdAt: Date

    public init(
        id: Identifier<TaskComment> = Identifier(),
        authorId: Identifier<TeamMember>,
        message: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.authorId = authorId
        self.message = message
        self.createdAt = createdAt
    }
}

