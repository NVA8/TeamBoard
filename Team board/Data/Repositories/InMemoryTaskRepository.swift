import Foundation
import _Concurrency

#if !canImport(FirebaseFirestore)

actor InMemoryTaskRepository: TaskRepository {
    private var tasksStorage: [Identifier<Board>: [Task]] = [:]
    private var continuations: [Identifier<Board>: [UUID: AsyncThrowingStream<[Task], Error>.Continuation]] = [:]

    nonisolated func observeTasks(boardId: Identifier<Board>) -> AsyncThrowingStream<[Task], Error> {
        AsyncThrowingStream<[Task], Error> { continuation in
            let id = UUID()
            _Concurrency.Task { await registerContinuation(id: id, boardId: boardId, continuation: continuation) }
            continuation.onTermination = { _ in
                _Concurrency.Task { await self.removeContinuation(id: id, boardId: boardId) }
            }
        }
    }

    func createTask(_ task: Task, boardId: Identifier<Board>, columnId: Identifier<TaskColumn>) async throws {
        var tasks = tasksStorage[boardId, default: []]
        var newTask = task
        newTask.status = status(for: columnId, existing: tasks)
        tasks.append(newTask)
        tasksStorage[boardId] = tasks
        await notify(boardId: boardId)
    }

    func moveTask(_ taskId: Identifier<Task>, to columnId: Identifier<TaskColumn>, order: Int) async throws {
        for (boardId, var tasks) in tasksStorage {
            if let index = tasks.firstIndex(where: { $0.id == taskId }) {
                tasks[index].status = status(for: columnId, existing: tasks)
                tasksStorage[boardId] = tasks
                await notify(boardId: boardId)
                break
            }
        }
    }

    func updateTask(_ task: Task) async throws {
        for (boardId, var tasks) in tasksStorage {
            if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[index] = task
                tasksStorage[boardId] = tasks
                await notify(boardId: boardId)
                break
            }
        }
    }

    func deleteTask(_ taskId: Identifier<Task>) async throws {
        for (boardId, var tasks) in tasksStorage {
            let newTasks = tasks.filter { $0.id != taskId }
            if newTasks.count != tasks.count {
                tasksStorage[boardId] = newTasks
                await notify(boardId: boardId)
                break
            }
        }
    }

    // MARK: - Helpers

    private func registerContinuation(
        id: UUID,
        boardId: Identifier<Board>,
        continuation: AsyncThrowingStream<[Task], Error>.Continuation
    ) {
        var boardContinuations = continuations[boardId, default: [:]]
        boardContinuations[id] = continuation
        continuations[boardId] = boardContinuations
        continuation.yield(tasksStorage[boardId, default: []])
    }

    private func removeContinuation(id: UUID, boardId: Identifier<Board>) {
        var boardContinuations = continuations[boardId, default: [:]]
        boardContinuations.removeValue(forKey: id)
        continuations[boardId] = boardContinuations
    }

    private func notify(boardId: Identifier<Board>) async {
        let tasks = tasksStorage[boardId, default: []]
        let boardContinuations = continuations[boardId, default: [:]]
        boardContinuations.values.forEach { $0.yield(tasks) }
    }

    private func status(
        for columnId: Identifier<TaskColumn>,
        existing: [Task]
    ) -> TaskStatus {
        // В демо-репозитории используем упрощённое сопоставление.
        let lowercaseId = columnId.rawValue.lowercased()
        if lowercaseId.contains("backlog") { return .backlog }
        if lowercaseId.contains("review") { return .review }
        if lowercaseId.contains("done") { return .done }
        if lowercaseId.contains("progress") { return .inProgress }
        if lowercaseId.contains("todo") { return .todo }
        if let last = existing.last { return last.status }
        return .todo
    }
}

#endif
