import Foundation

@MainActor
final class BoardDetailViewModel: ObservableObject {
    @Published var board: Board
    @Published var tasksByColumn: [Identifier<TaskColumn>: [Task]] = [:]
    @Published var errorMessage: String?

    private let environment: AppEnvironment
    private var streamTask: _Concurrency.Task<Void, Never>?

    init(board: Board, environment: AppEnvironment) {
        self.board = board
        self.environment = environment
        observeTasks()
    }

    func observeTasks() {
        streamTask?.cancel()
        streamTask = _Concurrency.Task {
            do {
                for try await tasks in environment.observeTasksUseCase.execute(boardId: board.id) {
                    await MainActor.run {
                        self.tasksByColumn = Dictionary(grouping: tasks, by: { task in
                            board.columns.first(where: { $0.taskIds.contains(task.id) })?.id ?? Identifier<TaskColumn>("unknown")
                        })
                    }
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func moveTask(
        _ task: Task,
        from sourceColumn: Identifier<TaskColumn>,
        to destinationColumn: Identifier<TaskColumn>,
        destinationIndex: Int
    ) {
        _Concurrency.Task {
            try? await environment.moveTaskUseCase.execute(
                taskId: task.id,
                columnId: destinationColumn,
                order: destinationIndex
            )
        }
    }
}
