import Foundation

public struct Task: Identifiable, Codable, Equatable, Sendable {
    public let id: Identifier<Task>
    public var title: String
    public var detail: String
    public var assigneeId: Identifier<TeamMember>?
    public var creatorId: Identifier<TeamMember>
    public var dueDate: Date?
    public var status: TaskStatus
    public var priority: TaskPriority
    public var attachments: [TaskAttachment]
    public var comments: [TaskComment]
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: Identifier<Task> = Identifier(),
        title: String,
        detail: String,
        assigneeId: Identifier<TeamMember>? = nil,
        creatorId: Identifier<TeamMember>,
        dueDate: Date? = nil,
        status: TaskStatus,
        priority: TaskPriority,
        attachments: [TaskAttachment] = [],
        comments: [TaskComment] = [],
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.assigneeId = assigneeId
        self.creatorId = creatorId
        self.dueDate = dueDate
        self.status = status
        self.priority = priority
        self.attachments = attachments
        self.comments = comments
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public enum TaskStatus: String, Codable, Sendable {
    case backlog
    case todo
    case inProgress
    case review
    case done
}

public enum TaskPriority: String, Codable, Sendable {
    case low
    case medium
    case high
    case critical
}

#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif

#if canImport(SwiftUI)
extension Task: Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .teamBoardTask)
    }
}

extension UTType {
    static let teamBoardTask = UTType(exportedAs: "com.valerijnikitin.teamboard.task")
}
#endif

