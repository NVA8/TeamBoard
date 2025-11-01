import Foundation

public protocol ObserveBoardsUseCase: Sendable {
    func execute(teamId: Identifier<Team>) -> AsyncThrowingStream<[Board], Error>
}

public struct DefaultObserveBoardsUseCase: ObserveBoardsUseCase {
    private let repository: BoardRepository

    public init(repository: BoardRepository) {
        self.repository = repository
    }

    public func execute(teamId: Identifier<Team>) -> AsyncThrowingStream<[Board], Error> {
        repository.observeBoards(for: teamId)
    }
}

