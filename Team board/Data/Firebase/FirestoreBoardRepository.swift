import Foundation
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

struct FirestoreBoardRepository: BoardRepository {
#if canImport(FirebaseFirestore)
    private let db = Firestore.firestore()
#endif
    private let mapper = FirestoreBoardMapper()
    private let cache: TaskCacheService

    init(cache: TaskCacheService) {
        self.cache = cache
    }

    func observeBoards(for teamId: Identifier<Team>) -> AsyncThrowingStream<[Board], Error> {
        AsyncThrowingStream { continuation in
#if canImport(FirebaseFirestore)
            let listener = db.collection("teams")
                .document(teamId.rawValue)
                .collection("boards")
                .addSnapshotListener { snapshot, error in
                    if let error {
                        continuation.finish(throwing: error)
                        return
                    }
                    guard let documents = snapshot?.documents else {
                        continuation.yield([])
                        return
                    }
                    let boards = documents.compactMap { mapper.mapBoard(document: $0) }
                    _Concurrency.Task { await cache.mergeBoards(boards, for: teamId) }
                    continuation.yield(boards)
                }
            continuation.onTermination = { _ in listener.remove() }
#else
            _Concurrency.Task {
                let cached = await cache.cachedBoards(for: teamId)
                continuation.yield(cached)
                continuation.finish()
            }
#endif
        }
    }

    func createBoard(_ board: Board, for teamId: Identifier<Team>) async throws {
#if canImport(FirebaseFirestore)
        try await db.collection("teams")
            .document(teamId.rawValue)
            .collection("boards")
            .document(board.id.rawValue)
            .setData(mapper.mapBoardData(board))
        await cache.mergeBoards([board], for: teamId)
#else
        throw RepositoryError.featureUnavailable
#endif
    }

    func updateBoard(_ board: Board, for teamId: Identifier<Team>) async throws {
#if canImport(FirebaseFirestore)
        try await db.collection("teams")
            .document(teamId.rawValue)
            .collection("boards")
            .document(board.id.rawValue)
            .setData(mapper.mapBoardData(board), merge: true)
        await cache.mergeBoards([board], for: teamId)
#else
        throw RepositoryError.featureUnavailable
#endif
    }

    func deleteBoard(_ boardId: Identifier<Board>, for teamId: Identifier<Team>) async throws {
#if canImport(FirebaseFirestore)
        try await db.collection("teams")
            .document(teamId.rawValue)
            .collection("boards")
            .document(boardId.rawValue)
            .delete()
        await cache.deleteBoard(boardId, for: teamId)
#else
        throw RepositoryError.featureUnavailable
#endif
    }
}
