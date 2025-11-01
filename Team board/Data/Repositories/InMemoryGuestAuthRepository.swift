import Foundation
import _Concurrency

#if !canImport(FirebaseAuth)

actor InMemoryGuestAuthRepository: UserRepository {
    private var current: TeamMember?
    private let defaultMembers: [TeamMember]
    private var memberContinuations: [UUID: AsyncThrowingStream<[TeamMember], Error>.Continuation] = [:]

    init() {
        let owner = TeamMember(
            id: Identifier("owner"),
            displayName: "Алексей Иванов",
            email: "alexey@example.com",
            avatarURL: nil,
            role: .owner
        )
        let designer = TeamMember(
            id: Identifier("designer"),
            displayName: "Мария Дизайнер",
            email: "maria@example.com",
            avatarURL: nil,
            role: .contributor
        )
        let developer = TeamMember(
            id: Identifier("developer"),
            displayName: "Иван Разработчик",
            email: "ivan@example.com",
            avatarURL: nil,
            role: .contributor
        )
        defaultMembers = [owner, designer, developer]
    }

    func currentUser() async throws -> TeamMember? {
        current
    }

    func signIn(email: String, password _: String) async throws -> TeamMember {
        let displayName = email.split(separator: "@").first.map { String($0).capitalized } ?? "Пользователь"
        let user = TeamMember(
            id: Identifier(email),
            displayName: displayName,
            email: email,
            avatarURL: nil,
            role: .contributor
        )
        current = user
        notifyMemberContinuations()
        return user
    }

    func signInWithApple(token: String) async throws -> TeamMember {
        let user = TeamMember(
            id: Identifier(token),
            displayName: "Apple User",
            email: "",
            avatarURL: nil,
            role: .contributor
        )
        current = user
        notifyMemberContinuations()
        return user
    }

    func signInAnonymously() async throws -> TeamMember {
        if let current, current.email.isEmpty {
            return current
        }
        let guest = TeamMember(
            id: Identifier("guest-\(UUID().uuidString)"),
            displayName: "Гость",
            email: "",
            avatarURL: nil,
            role: .viewer
        )
        current = guest
        notifyMemberContinuations()
        return guest
    }

    func signOut() async throws {
        current = nil
        notifyMemberContinuations()
    }

    nonisolated func observeTeamMembers(teamId _: Identifier<Team>) -> AsyncThrowingStream<[TeamMember], Error> {
        AsyncThrowingStream<[TeamMember], Error>(bufferingPolicy: .unbounded) { continuation in
            let id = UUID()
            _Concurrency.Task {
                await self.registerContinuation(id: id, continuation: continuation)
            }
            continuation.onTermination = { _ in
                _Concurrency.Task { await self.removeContinuation(id) }
            }
        }
    }

    private func registerContinuation(
        id: UUID,
        continuation: AsyncThrowingStream<[TeamMember], Error>.Continuation
    ) {
        memberContinuations[id] = continuation
        continuation.yield(snapshotMembers())
    }

    private func snapshotMembers() -> [TeamMember] {
        var members = defaultMembers
        if let current {
            if let index = members.firstIndex(where: { $0.id == current.id }) {
                members[index] = current
            } else {
                members.append(current)
            }
        }
        return members
    }

    private func notifyMemberContinuations() {
        let members = snapshotMembers()
        for continuation in memberContinuations.values {
            continuation.yield(members)
        }
    }

    private func removeContinuation(_ id: UUID) {
        memberContinuations.removeValue(forKey: id)
    }
}

#endif
