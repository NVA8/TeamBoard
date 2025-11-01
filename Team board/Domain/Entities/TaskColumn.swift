import Foundation

public struct TaskColumn: Identifiable, Codable, Equatable, Sendable {
    public let id: Identifier<TaskColumn>
    public var title: String
    public var order: Int
    public var taskIds: [Identifier<Task>]

    public init(
        id: Identifier<TaskColumn> = Identifier(),
        title: String,
        order: Int,
        taskIds: [Identifier<Task>] = []
    ) {
        self.id = id
        self.title = title
        self.order = order
        self.taskIds = taskIds
    }
}

