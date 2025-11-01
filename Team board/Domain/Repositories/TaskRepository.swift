import Foundation

public protocol TaskRepository: Sendable {
    func observeTasks(boardId: Identifier<Board>) -> AsyncThrowingStream<[Task], Error>
    func createTask(_ task: Task, boardId: Identifier<Board>, columnId: Identifier<TaskColumn>) async throws
    func moveTask(_ taskId: Identifier<Task>, to columnId: Identifier<TaskColumn>, order: Int) async throws
    func updateTask(_ task: Task) async throws
    func deleteTask(_ taskId: Identifier<Task>) async throws
}

