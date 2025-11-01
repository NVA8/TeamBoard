import Foundation

public protocol ObserveCurrentUserUseCase: Sendable {
    func execute() async throws -> TeamMember?
}

public protocol SignInEmailUseCase: Sendable {
    func execute(email: String, password: String) async throws -> TeamMember
}

public protocol SignOutUseCase: Sendable {
    func execute() async throws
}

public struct DefaultObserveCurrentUserUseCase: ObserveCurrentUserUseCase {
    private let repository: UserRepository

    public init(repository: UserRepository) {
        self.repository = repository
    }

    public func execute() async throws -> TeamMember? {
        try await repository.currentUser()
    }
}

public struct DefaultSignInEmailUseCase: SignInEmailUseCase {
    private let repository: UserRepository

    public init(repository: UserRepository) {
        self.repository = repository
    }

    public func execute(email: String, password: String) async throws -> TeamMember {
        try await repository.signIn(email: email, password: password)
    }
}

public struct DefaultSignOutUseCase: SignOutUseCase {
    private let repository: UserRepository

    public init(repository: UserRepository) {
        self.repository = repository
    }

    public func execute() async throws {
        try await repository.signOut()
    }
}

