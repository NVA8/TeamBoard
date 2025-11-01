import Foundation

public struct Board: Identifiable, Codable, Equatable, Sendable {
    public let id: Identifier<Board>
    public var name: String
    public var description: String
    public var ownerId: Identifier<TeamMember>
    public var columns: [TaskColumn]
    public var members: [Identifier<TeamMember>]
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: Identifier<Board> = Identifier(),
        name: String,
        description: String,
        ownerId: Identifier<TeamMember>,
        columns: [TaskColumn],
        members: [Identifier<TeamMember>],
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.ownerId = ownerId
        self.columns = columns
        self.members = members
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

