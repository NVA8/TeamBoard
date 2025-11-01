import Foundation
import _Concurrency

#if !canImport(FirebaseFirestore)

actor InMemoryBoardRepository: BoardRepository {
    private var boardsStorage: [Identifier<Team>: [Board]] = [:]
    private var streamContinuations: [Identifier<Team>: [UUID: AsyncThrowingStream<[Board], Error>.Continuation]] = [:]

    init() {
        let demoTeam = Identifier<Team>("demo-team")
        let sampleBoard = Board(
            id: Identifier("design-sprint"),
            name: "Design Sprint",
            description: "Задачи по обновлению клиентского интерфейса.",
            ownerId: Identifier<TeamMember>("owner"),
            columns: [
                TaskColumn(title: "Backlog", order: 0),
                TaskColumn(title: "В работе", order: 1),
                TaskColumn(title: "Ревью", order: 2),
                TaskColumn(title: "Готово", order: 3)
            ],
            members: [Identifier("owner"), Identifier("designer"), Identifier("developer")]
        )
        boardsStorage[demoTeam] = [sampleBoard]
    }

    nonisolated func observeBoards(for teamId: Identifier<Team>) -> AsyncThrowingStream<[Board], Error> {
        AsyncThrowingStream<[Board], Error> { continuation in
            let id = UUID()
            _Concurrency.Task { await registerContinuation(id: id, teamId: teamId, continuation: continuation) }
            continuation.onTermination = { _ in
                _Concurrency.Task { await self.removeContinuation(id: id, teamId: teamId) }
            }
        }
    }

    func createBoard(_ board: Board, for teamId: Identifier<Team>) async throws {
        var boards = boardsStorage[teamId, default: []]
        boards.append(board)
        boardsStorage[teamId] = boards
        await notify(teamId: teamId)
    }

    func updateBoard(_ board: Board, for teamId: Identifier<Team>) async throws {
        guard var boards = boardsStorage[teamId], let index = boards.firstIndex(where: { $0.id == board.id }) else {
            throw RepositoryError.notFound
        }
        boards[index] = board
        boardsStorage[teamId] = boards
        await notify(teamId: teamId)
    }

    func deleteBoard(_ boardId: Identifier<Board>, for teamId: Identifier<Team>) async throws {
        var boards = boardsStorage[teamId, default: []]
        boards.removeAll { $0.id == boardId }
        boardsStorage[teamId] = boards
        await notify(teamId: teamId)
    }

    // MARK: - Helpers

    private func registerContinuation(
        id: UUID,
        teamId: Identifier<Team>,
        continuation: AsyncThrowingStream<[Board], Error>.Continuation
    ) {
        var teamContinuations = streamContinuations[teamId, default: [:]]
        teamContinuations[id] = continuation
        streamContinuations[teamId] = teamContinuations
        continuation.yield(boardsStorage[teamId, default: []])
    }

    private func removeContinuation(id: UUID, teamId: Identifier<Team>) {
        var teamContinuations = streamContinuations[teamId, default: [:]]
        teamContinuations.removeValue(forKey: id)
        streamContinuations[teamId] = teamContinuations
    }

    private func notify(teamId: Identifier<Team>) async {
        let boards = boardsStorage[teamId, default: []]
        let continuations = streamContinuations[teamId, default: [:]]
        continuations.values.forEach { $0.yield(boards) }
    }
}

#endif
