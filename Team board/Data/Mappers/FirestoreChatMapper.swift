import Foundation

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

struct FirestoreChatMapper {
#if canImport(FirebaseFirestore)
    func mapMessage(document: QueryDocumentSnapshot) -> ChatMessage? {
        let data = document.data()
        guard
            let authorId = data["authorId"] as? String,
            let channelId = data["channelId"] as? String,
            let body = data["body"] as? String,
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
        else {
            return nil
        }

        let attachments = (data["attachments"] as? [[String: Any]] ?? []).compactMap { attachmentData -> TaskAttachment? in
            guard
                let id = attachmentData["id"] as? String,
                let fileName = attachmentData["fileName"] as? String,
                let fileURLString = attachmentData["fileURL"] as? String,
                let fileURL = URL(string: fileURLString),
                let uploadedBy = attachmentData["uploadedBy"] as? String,
                let uploadedAt = (attachmentData["uploadedAt"] as? Timestamp)?.dateValue()
            else {
                return nil
            }
            return TaskAttachment(
                id: Identifier<TaskAttachment>(id),
                fileName: fileName,
                fileURL: fileURL,
                uploadedBy: Identifier<TeamMember>(uploadedBy),
                uploadedAt: uploadedAt
            )
        }

        return ChatMessage(
            id: Identifier<ChatMessage>(document.documentID),
            channelId: Identifier<ChatChannel>(channelId),
            authorId: Identifier<TeamMember>(authorId),
            body: body,
            attachments: attachments,
            createdAt: createdAt,
            isSystemMessage: data["isSystemMessage"] as? Bool ?? false
        )
    }

    func mapMessageData(_ message: ChatMessage) -> [String: Any] {
        [
            "authorId": message.authorId.rawValue,
            "channelId": message.channelId.rawValue,
            "body": message.body,
            "isSystemMessage": message.isSystemMessage,
            "attachments": message.attachments.map { attachment in
                [
                    "id": attachment.id.rawValue,
                    "fileName": attachment.fileName,
                    "fileURL": attachment.fileURL.absoluteString,
                    "uploadedBy": attachment.uploadedBy.rawValue,
                    "uploadedAt": Timestamp(date: attachment.uploadedAt)
                ]
            },
            "createdAt": Timestamp(date: message.createdAt)
        ]
    }

    func mapChannelData(_ channel: ChatChannel) -> [String: Any] {
        [
            "title": channel.title,
            "participantIds": channel.participantIds.map(\.rawValue),
            "linkedBoardId": channel.linkedBoardId?.rawValue as Any,
            "createdAt": Timestamp(date: channel.createdAt)
        ]
    }
#else
    func mapMessage(document _: AnyObject) -> ChatMessage? { nil }
    func mapMessageData(_: ChatMessage) -> [String: Any] { [:] }
    func mapChannelData(_: ChatChannel) -> [String: Any] { [:] }
#endif
}

