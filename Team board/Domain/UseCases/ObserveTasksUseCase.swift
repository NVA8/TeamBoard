import Foundation

public protocol ObserveTasksUseCase: Sendable {
    func execute(boardId: Identifier<Board>) -> AsyncThrowingStream<[Task], Error>
}

public struct DefaultObserveTasksUseCase: ObserveTasksUseCase {
    private let repository: TaskRepository

    public init(repository: TaskRepository) {
        self.repository = repository
    }

    public func execute(boardId: Identifier<Board>) -> AsyncThrowingStream<[Task], Error> {
        repository.observeTasks(boardId: boardId)
    }
}

