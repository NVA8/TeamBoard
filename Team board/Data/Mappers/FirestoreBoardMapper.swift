import Foundation

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

struct FirestoreBoardMapper {
#if canImport(FirebaseFirestore)
    func mapBoard(document: QueryDocumentSnapshot) -> Board? {
        let data = document.data()
        guard
            let name = data["name"] as? String,
            let description = data["description"] as? String,
            let ownerId = data["ownerId"] as? String,
            let memberIds = data["members"] as? [String],
            let columnsData = data["columns"] as? [[String: Any]],
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue(),
            let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue()
        else {
            return nil
        }

        let columns: [TaskColumn] = columnsData.enumerated().compactMap { index, columnData in
            guard let title = columnData["title"] as? String,
                  let id = columnData["id"] as? String else { return nil }
            let tasks = (columnData["taskIds"] as? [String] ?? []).map { Identifier<Task>($0) }
            return TaskColumn(
                id: Identifier<TaskColumn>(id),
                title: title,
                order: columnData["order"] as? Int ?? index,
                taskIds: tasks
            )
        }

        return Board(
            id: Identifier<Board>(document.documentID),
            name: name,
            description: description,
            ownerId: Identifier<TeamMember>(ownerId),
            columns: columns,
            members: memberIds.map { Identifier<TeamMember>($0) },
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    func mapBoardData(_ board: Board) -> [String: Any] {
        [
            "name": board.name,
            "description": board.description,
            "ownerId": board.ownerId.rawValue,
            "members": board.members.map(\.rawValue),
            "columns": board.columns.enumerated().map { index, column in
                [
                    "id": column.id.rawValue,
                    "title": column.title,
                    "order": column.order,
                    "taskIds": column.taskIds.map(\.rawValue),
                    "index": index
                ] as [String: Any]
            },
            "createdAt": Timestamp(date: board.createdAt),
            "updatedAt": Timestamp(date: board.updatedAt)
        ]
    }
#else
    func mapBoard(document _: AnyObject) -> Board? { nil }
    func mapBoardData(_: Board) -> [String: Any] { [:] }
#endif
}

