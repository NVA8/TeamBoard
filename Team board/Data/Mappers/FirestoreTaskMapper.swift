import Foundation

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

struct FirestoreTaskMapper {
#if canImport(FirebaseFirestore)
    func mapTask(document: QueryDocumentSnapshot) -> Task? {
        let data = document.data()
        guard
            let title = data["title"] as? String,
            let detail = data["detail"] as? String,
            let creatorId = data["creatorId"] as? String,
            let statusRaw = data["status"] as? String,
            let priorityRaw = data["priority"] as? String,
            let status = TaskStatus(rawValue: statusRaw),
            let priority = TaskPriority(rawValue: priorityRaw),
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue(),
            let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue()
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

        let comments = (data["comments"] as? [[String: Any]] ?? []).compactMap { commentData -> TaskComment? in
            guard
                let id = commentData["id"] as? String,
                let authorId = commentData["authorId"] as? String,
                let message = commentData["message"] as? String,
                let createdAt = (commentData["createdAt"] as? Timestamp)?.dateValue()
            else {
                return nil
            }
            return TaskComment(
                id: Identifier<TaskComment>(id),
                authorId: Identifier<TeamMember>(authorId),
                message: message,
                createdAt: createdAt
            )
        }

        return Task(
            id: Identifier<Task>(document.documentID),
            title: title,
            detail: detail,
            assigneeId: (data["assigneeId"] as? String).map { Identifier<TeamMember>($0) },
            creatorId: Identifier<TeamMember>(creatorId),
            dueDate: (data["dueDate"] as? Timestamp)?.dateValue(),
            status: status,
            priority: priority,
            attachments: attachments,
            comments: comments,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    func mapTaskData(_ task: Task, columnId: Identifier<TaskColumn>) -> [String: Any] {
        [
            "id": task.id.rawValue,
            "title": task.title,
            "detail": task.detail,
            "assigneeId": task.assigneeId?.rawValue as Any,
            "creatorId": task.creatorId.rawValue,
            "dueDate": task.dueDate.map(Timestamp.init(date:)),
            "status": task.status.rawValue,
            "priority": task.priority.rawValue,
            "attachments": task.attachments.map { attachment in
                [
                    "id": attachment.id.rawValue,
                    "fileName": attachment.fileName,
                    "fileURL": attachment.fileURL.absoluteString,
                    "uploadedBy": attachment.uploadedBy.rawValue,
                    "uploadedAt": Timestamp(date: attachment.uploadedAt)
                ] as [String: Any]
            },
            "comments": task.comments.map { comment in
                [
                    "id": comment.id.rawValue,
                    "authorId": comment.authorId.rawValue,
                    "message": comment.message,
                    "createdAt": Timestamp(date: comment.createdAt)
                ]
            },
            // TODO: Compute order via column aggregated data once drag ordering persistence is implemented.
            "order": 0,
            "columnId": columnId.rawValue,
            "createdAt": Timestamp(date: task.createdAt),
            "updatedAt": Timestamp(date: task.updatedAt)
        ]
    }
#else
    func mapTask(document _: AnyObject) -> Task? { nil }
    func mapTaskData(_: Task, columnId _: Identifier<TaskColumn>) -> [String: Any] { [:] }
#endif
}
