import Foundation
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

struct FirebaseAuthRepository: UserRepository {
    private let mapper: FirebaseUserMapper

    init(mapper: FirebaseUserMapper = FirebaseUserMapper()) {
        self.mapper = mapper
    }

    func currentUser() async throws -> TeamMember? {
#if canImport(FirebaseAuth)
        guard let user = Auth.auth().currentUser else { return nil }
        return try await mapper.map(user: user)
#else
        return nil
#endif
    }

    func signIn(email: String, password: String) async throws -> TeamMember {
#if canImport(FirebaseAuth)
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        return try await mapper.map(user: result.user)
#else
        throw RepositoryError.featureUnavailable
#endif
    }

    func signInWithApple(token: String) async throws -> TeamMember {
#if canImport(FirebaseAuth)
        let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: token, rawNonce: UUID().uuidString)
        let result = try await Auth.auth().signIn(with: credential)
        return try await mapper.map(user: result.user)
#else
        throw RepositoryError.featureUnavailable
#endif
    }

    func signOut() async throws {
#if canImport(FirebaseAuth)
        try Auth.auth().signOut()
#endif
    }

    func observeTeamMembers(teamId: Identifier<Team>) -> AsyncThrowingStream<[TeamMember], Error> {
        AsyncThrowingStream { continuation in
            _Concurrency.Task {
                do {
                    for try await snapshot in FirebaseTeamMembersListener(teamId: teamId) {
                        continuation.yield(snapshot)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

private struct FirebaseTeamMembersListener: AsyncSequence {
    typealias Element = [TeamMember]
    typealias AsyncIterator = Iterator

    struct Iterator: AsyncIteratorProtocol {
        let teamId: Identifier<Team>
        let mapper = FirebaseUserMapper()
#if canImport(FirebaseFirestore)
        var listener: ListenerRegistration?
#endif
        var didStart = false

        mutating func next() async throws -> Element? {
#if canImport(FirebaseFirestore)
            if !didStart {
                didStart = true
                return try await withCheckedThrowingContinuation { continuation in
                    listener = Firestore.firestore()
                        .collection("teams")
                        .document(teamId.rawValue)
                        .collection("members")
                        .addSnapshotListener { snapshot, error in
                            if let error {
                                continuation.resume(throwing: error)
                                return
                            }
                            guard let documents = snapshot?.documents else {
                                continuation.resume(returning: [])
                                return
                            }
                            let members = documents.compactMap { try? mapper.map(memberDocument: $0) }
                            continuation.resume(returning: members)
                        }
                }
            } else {
                return try await _Concurrency.Task.never()
            }
#else
            return nil
#endif
        }
    }

    let teamId: Identifier<Team>

    func makeAsyncIterator() -> Iterator {
        Iterator(teamId: teamId)
    }
}
