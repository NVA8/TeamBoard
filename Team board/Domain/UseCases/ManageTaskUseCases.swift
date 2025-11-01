import Foundation

public protocol CreateTaskUseCase: Sendable {
    func execute(_ task: Task, boardId: Identifier<Board>, columnId: Identifier<TaskColumn>) async throws
}

public protocol MoveTaskUseCase: Sendable {
    func execute(taskId: Identifier<Task>, columnId: Identifier<TaskColumn>, order: Int) async throws
}

public protocol UpdateTaskUseCase: Sendable {
    func execute(_ task: Task) async throws
}

public struct DefaultCreateTaskUseCase: CreateTaskUseCase {
    private let repository: TaskRepository

    public init(repository: TaskRepository) {
        self.repository = repository
    }

    public func execute(_ task: Task, boardId: Identifier<Board>, columnId: Identifier<TaskColumn>) async throws {
        try await repository.createTask(task, boardId: boardId, columnId: columnId)
    }
}

public struct DefaultMoveTaskUseCase: MoveTaskUseCase {
    private let repository: TaskRepository

    public init(repository: TaskRepository) {
        self.repository = repository
    }

    public func execute(taskId: Identifier<Task>, columnId: Identifier<TaskColumn>, order: Int) async throws {
        try await repository.moveTask(taskId, to: columnId, order: order)
    }
}

public struct DefaultUpdateTaskUseCase: UpdateTaskUseCase {
    private let repository: TaskRepository

    public init(repository: TaskRepository) {
        self.repository = repository
    }

    public func execute(_ task: Task) async throws {
        try await repository.updateTask(task)
    }
}

