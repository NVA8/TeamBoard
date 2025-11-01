import CoreData
import Foundation

actor TaskCacheService {
    private let container: NSPersistentContainer

    init(container: NSPersistentContainer = TaskCacheService.makeContainer()) {
        self.container = container
        container.loadPersistentStores { _, error in
            if let error {
                assertionFailure("Failed to load CoreData store: \(error)")
            }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func mergeBoards(_ boards: [Board], for teamId: Identifier<Team>) async {
        guard !boards.isEmpty else { return }
        let context = container.newBackgroundContext()
        await context.perform {
            for board in boards {
                let request: NSFetchRequest<BoardEntity> = BoardEntity.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", board.id.rawValue)
                let boardEntity = (try? context.fetch(request).first) ?? BoardEntity(context: context)
                boardEntity.id = board.id.rawValue
                boardEntity.teamId = teamId.rawValue
                boardEntity.name = board.name
                boardEntity.boardDescription = board.description
                boardEntity.ownerId = board.ownerId.rawValue
                boardEntity.updatedAt = board.updatedAt
                boardEntity.createdAt = board.createdAt
            }
            try? context.save()
        }
    }

    func deleteBoard(_ boardId: Identifier<Board>, for teamId: Identifier<Team>) async {
        let context = container.newBackgroundContext()
        await context.perform {
            let request: NSFetchRequest<BoardEntity> = BoardEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@ AND teamId == %@", boardId.rawValue, teamId.rawValue)
            if let entity = try? context.fetch(request).first {
                context.delete(entity)
            }
            try? context.save()
        }
    }

    func cachedBoards(for teamId: Identifier<Team>) async -> [Board] {
        let context = container.viewContext
        return await context.perform {
            let request: NSFetchRequest<BoardEntity> = BoardEntity.fetchRequest()
            request.predicate = NSPredicate(format: "teamId == %@", teamId.rawValue)
            guard let entities = try? context.fetch(request) else { return [] }
            return entities.map {
                Board(
                    id: Identifier<Board>($0.id ?? ""),
                    name: $0.name ?? "",
                    description: $0.boardDescription ?? "",
                    ownerId: Identifier<TeamMember>($0.ownerId ?? ""),
                    columns: [],
                    members: [],
                    createdAt: $0.createdAt ?? .now,
                    updatedAt: $0.updatedAt ?? .now
                )
            }
        }
    }
}

private extension TaskCacheService {
    static func makeContainer() -> NSPersistentContainer {
        NSPersistentContainer(name: "TeamBoardModel", managedObjectModel: makeModel())
    }

    static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let boardEntity = NSEntityDescription()
        boardEntity.name = "BoardEntity"
        boardEntity.managedObjectClassName = NSStringFromClass(BoardEntity.self)

        let idAttribute = NSAttributeDescription()
        idAttribute.name = "id"
        idAttribute.attributeType = .stringAttributeType
        idAttribute.isOptional = false

        let teamIdAttribute = NSAttributeDescription()
        teamIdAttribute.name = "teamId"
        teamIdAttribute.attributeType = .stringAttributeType
        teamIdAttribute.isOptional = false

        let nameAttribute = NSAttributeDescription()
        nameAttribute.name = "name"
        nameAttribute.attributeType = .stringAttributeType
        nameAttribute.isOptional = false

        let descriptionAttribute = NSAttributeDescription()
        descriptionAttribute.name = "boardDescription"
        descriptionAttribute.attributeType = .stringAttributeType
        descriptionAttribute.isOptional = true

        let ownerAttribute = NSAttributeDescription()
        ownerAttribute.name = "ownerId"
        ownerAttribute.attributeType = .stringAttributeType
        ownerAttribute.isOptional = true

        let createdAtAttribute = NSAttributeDescription()
        createdAtAttribute.name = "createdAt"
        createdAtAttribute.attributeType = .dateAttributeType
        createdAtAttribute.isOptional = true

        let updatedAtAttribute = NSAttributeDescription()
        updatedAtAttribute.name = "updatedAt"
        updatedAtAttribute.attributeType = .dateAttributeType
        updatedAtAttribute.isOptional = true

        boardEntity.properties = [
            idAttribute,
            teamIdAttribute,
            nameAttribute,
            descriptionAttribute,
            ownerAttribute,
            createdAtAttribute,
            updatedAtAttribute
        ]

        model.entities = [boardEntity]
        return model
    }
}

@objc(BoardEntity)
final class BoardEntity: NSManagedObject {
    @NSManaged var id: String?
    @NSManaged var teamId: String?
    @NSManaged var name: String?
    @NSManaged var boardDescription: String?
    @NSManaged var ownerId: String?
    @NSManaged var createdAt: Date?
    @NSManaged var updatedAt: Date?
}

extension BoardEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<BoardEntity> {
        NSFetchRequest<BoardEntity>(entityName: "BoardEntity")
    }
}

