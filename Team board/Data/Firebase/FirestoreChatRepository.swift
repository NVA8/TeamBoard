import Foundation

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

struct FirestoreChatRepository: ChatRepository {
#if canImport(FirebaseFirestore)
    private let db = Firestore.firestore()
#endif
    private let mapper = FirestoreChatMapper()

    func observeMessages(channelId: Identifier<ChatChannel>) -> AsyncThrowingStream<[ChatMessage], Error> {
        AsyncThrowingStream { continuation in
#if canImport(FirebaseFirestore)
            let listener = db.collection("channels")
                .document(channelId.rawValue)
                .collection("messages")
                .order(by: "createdAt", descending: false)
                .addSnapshotListener { snapshot, error in
                    if let error {
                        continuation.finish(throwing: error)
                        return
                    }
                    guard let documents = snapshot?.documents else {
                        continuation.yield([])
                        return
                    }
                    continuation.yield(documents.compactMap { mapper.mapMessage(document: $0) })
                }
            continuation.onTermination = { _ in listener.remove() }
#else
            continuation.finish(throwing: RepositoryError.featureUnavailable)
#endif
        }
    }

    func sendMessage(_ message: ChatMessage) async throws {
#if canImport(FirebaseFirestore)
        try await db.collection("channels")
            .document(message.channelId.rawValue)
            .collection("messages")
            .document(message.id.rawValue)
            .setData(mapper.mapMessageData(message))
#else
        throw RepositoryError.featureUnavailable
#endif
    }

    func createChannel(_ channel: ChatChannel) async throws {
#if canImport(FirebaseFirestore)
        try await db.collection("channels")
            .document(channel.id.rawValue)
            .setData(mapper.mapChannelData(channel))
#else
        throw RepositoryError.featureUnavailable
#endif
    }
}

