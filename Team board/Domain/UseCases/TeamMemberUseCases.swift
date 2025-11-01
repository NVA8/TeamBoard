import Foundation

public protocol ObserveTeamMembersUseCase: Sendable {
    func execute(teamId: Identifier<Team>) -> AsyncThrowingStream<[TeamMember], Error>
}

public struct DefaultObserveTeamMembersUseCase: ObserveTeamMembersUseCase {
    private let repository: UserRepository

    public init(repository: UserRepository) {
        self.repository = repository
    }

    public func execute(teamId: Identifier<Team>) -> AsyncThrowingStream<[TeamMember], Error> {
        repository.observeTeamMembers(teamId: teamId)
    }
}

