import Combine
import Foundation

@MainActor
final class BoardsViewModel: ObservableObject {
    @Published var boards: [Board] = []
    @Published var selectedTeamId: Identifier<Team> = Identifier("demo-team")
    @Published var isLoading = false
    @Published var errorMessage: String?

    let environment: AppEnvironment
    private var cancellables = Set<AnyCancellable>()
    private var streamTask: _Concurrency.Task<Void, Never>?

    init(environment: AppEnvironment) {
        self.environment = environment
        observeBoards()
    }

    func observeBoards() {
        streamTask?.cancel()
        isLoading = true
        streamTask = _Concurrency.Task {
            do {
                for try await boards in environment.observeBoardsUseCase.execute(teamId: selectedTeamId) {
                    await MainActor.run {
                        self.boards = boards.sorted(by: { $0.updatedAt > $1.updatedAt })
                        self.isLoading = false
                    }
                }
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    func createBoard() {
        _Concurrency.Task {
            let newBoard = Board(
                name: "Новая доска",
                description: "Экспериментальная доска",
                ownerId: Identifier<TeamMember>("owner"),
                columns: [
                    TaskColumn(title: "Backlog", order: 0),
                    TaskColumn(title: "В работе", order: 1),
                    TaskColumn(title: "Готово", order: 2)
                ],
                members: []
            )
            try? await environment.boardRepository.createBoard(newBoard, for: selectedTeamId)
        }
    }

    func deleteBoard(_ board: Board) {
        _Concurrency.Task {
            try? await environment.boardRepository.deleteBoard(board.id, for: selectedTeamId)
        }
    }
}
