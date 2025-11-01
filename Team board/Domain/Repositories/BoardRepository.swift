import Foundation

public protocol BoardRepository: Sendable {
    func observeBoards(for teamId: Identifier<Team>) -> AsyncThrowingStream<[Board], Error>
    func createBoard(_ board: Board, for teamId: Identifier<Team>) async throws
    func updateBoard(_ board: Board, for teamId: Identifier<Team>) async throws
    func deleteBoard(_ boardId: Identifier<Board>, for teamId: Identifier<Team>) async throws
}

public struct Team: Identifiable, Codable, Equatable, Sendable {
    public let id: Identifier<Team>
    public var name: String
    public var logoURL: URL?
    public var members: [TeamMember]
    public var createdAt: Date

    public init(
        id: Identifier<Team> = Identifier(),
        name: String,
        logoURL: URL? = nil,
        members: [TeamMember],
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.logoURL = logoURL
        self.members = members
        self.createdAt = createdAt
    }
}

