import Foundation

public struct TaskAttachment: Identifiable, Codable, Equatable, Sendable {
    public let id: Identifier<TaskAttachment>
    public var fileName: String
    public var fileURL: URL
    public var uploadedBy: Identifier<TeamMember>
    public var uploadedAt: Date

    public init(
        id: Identifier<TaskAttachment> = Identifier(),
        fileName: String,
        fileURL: URL,
        uploadedBy: Identifier<TeamMember>,
        uploadedAt: Date = .now
    ) {
        self.id = id
        self.fileName = fileName
        self.fileURL = fileURL
        self.uploadedBy = uploadedBy
        self.uploadedAt = uploadedAt
    }
}

