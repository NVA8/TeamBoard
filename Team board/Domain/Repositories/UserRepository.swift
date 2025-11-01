import Foundation

public protocol UserRepository: Sendable {
    func currentUser() async throws -> TeamMember?
    func signIn(email: String, password: String) async throws -> TeamMember
    func signInWithApple(token: String) async throws -> TeamMember
    func signOut() async throws
    func observeTeamMembers(teamId: Identifier<Team>) -> AsyncThrowingStream<[TeamMember], Error>
}

