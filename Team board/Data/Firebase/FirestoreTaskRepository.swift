import Foundation

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

struct FirestoreTaskRepository: TaskRepository {
    private let mapper = FirestoreTaskMapper()
    private let cache: TaskCacheService

#if canImport(FirebaseFirestore)
    private let db = Firestore.firestore()
#endif

    init(cache: TaskCacheService) {
        self.cache = cache
    }

    func observeTasks(boardId: Identifier<Board>) -> AsyncThrowingStream<[Task], Error> {
        AsyncThrowingStream { continuation in
#if canImport(FirebaseFirestore)
            let listener = db.collection("boards")
                .document(boardId.rawValue)
                .collection("tasks")
                .addSnapshotListener { snapshot, error in
                    if let error {
                        continuation.finish(throwing: error)
                        return
                    }
                    guard let documents = snapshot?.documents else {
                        continuation.yield([])
                        return
                    }
                    let tasks = documents.compactMap { mapper.mapTask(document: $0) }
                    continuation.yield(tasks)
                }
            continuation.onTermination = { _ in listener.remove() }
#else
            continuation.finish(throwing: RepositoryError.featureUnavailable)
#endif
        }
    }

    func createTask(_ task: Task, boardId: Identifier<Board>, columnId: Identifier<TaskColumn>) async throws {
#if canImport(FirebaseFirestore)
        try await db.collection("boards")
            .document(boardId.rawValue)
            .collection("tasks")
            .document(task.id.rawValue)
            .setData(mapper.mapTaskData(task, columnId: columnId))
#else
        throw RepositoryError.featureUnavailable
#endif
    }

    func moveTask(_ taskId: Identifier<Task>, to columnId: Identifier<TaskColumn>, order: Int) async throws {
#if canImport(FirebaseFirestore)
        try await db.collectionGroup("tasks")
            .whereField("id", isEqualTo: taskId.rawValue)
            .getDocuments() { snapshot, error in
                if let error {
                    assertionFailure("Move task failed: \(error)")
                    return
                }
                snapshot?.documents.forEach { doc in
                    doc.reference.setData([
                        "columnId": columnId.rawValue,
                        "order": order,
                        "updatedAt": Timestamp(date: .now)
                    ], merge: true)
                }
            }
#else
        throw RepositoryError.featureUnavailable
#endif
    }

    func updateTask(_ task: Task) async throws {
#if canImport(FirebaseFirestore)
        try await db.collectionGroup("tasks")
            .whereField("id", isEqualTo: task.id.rawValue)
            .getDocuments() { snapshot, error in
                if let error {
                    assertionFailure("Update task failed: \(error)")
                    return
                }
                snapshot?.documents.forEach { doc in
                    doc.reference.setData(mapper.mapTaskData(task, columnId: Identifier<TaskColumn>(doc["columnId"] as? String ?? "")), merge: true)
                }
            }
#else
        throw RepositoryError.featureUnavailable
#endif
    }

    func deleteTask(_ taskId: Identifier<Task>) async throws {
#if canImport(FirebaseFirestore)
        try await db.collectionGroup("tasks")
            .whereField("id", isEqualTo: taskId.rawValue)
            .getDocuments() { snapshot, error in
                if let error {
                    assertionFailure("Delete task failed: \(error)")
                    return
                }
                snapshot?.documents.forEach { doc in
                    doc.reference.delete()
                }
            }
#else
        throw RepositoryError.featureUnavailable
#endif
    }
}

