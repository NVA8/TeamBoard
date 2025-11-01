import Foundation

public struct TeamMember: Identifiable, Codable, Equatable, Sendable {
    public let id: Identifier<TeamMember>
    public var displayName: String
    public var email: String
    public var avatarURL: URL?
    public var role: TeamRole
    public var isActive: Bool

    public init(
        id: Identifier<TeamMember> = Identifier(),
        displayName: String,
        email: String,
        avatarURL: URL? = nil,
        role: TeamRole,
        isActive: Bool = true
    ) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.avatarURL = avatarURL
        self.role = role
        self.isActive = isActive
    }
}

public enum TeamRole: String, Codable, Sendable {
    case owner
    case admin
    case contributor
    case viewer
}

