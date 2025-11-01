import Foundation

@MainActor
final class AppEnvironment: ObservableObject {
    let taskCache = TaskCacheService()

    lazy var boardRepository: BoardRepository = FirestoreBoardRepository(cache: taskCache)
    lazy var taskRepository: TaskRepository = FirestoreTaskRepository(cache: taskCache)
    lazy var chatRepository: ChatRepository = FirestoreChatRepository()
    lazy var userRepository: UserRepository = FirebaseAuthRepository()
    lazy var notificationRepository: NotificationRepository = PushNotificationRepository()

    lazy var observeBoardsUseCase: ObserveBoardsUseCase = DefaultObserveBoardsUseCase(repository: boardRepository)
    lazy var observeTasksUseCase: ObserveTasksUseCase = DefaultObserveTasksUseCase(repository: taskRepository)
    lazy var createTaskUseCase: CreateTaskUseCase = DefaultCreateTaskUseCase(repository: taskRepository)
    lazy var moveTaskUseCase: MoveTaskUseCase = DefaultMoveTaskUseCase(repository: taskRepository)
    lazy var updateTaskUseCase: UpdateTaskUseCase = DefaultUpdateTaskUseCase(repository: taskRepository)
    lazy var observeChatMessagesUseCase: ObserveChatMessagesUseCase = DefaultObserveChatMessagesUseCase(repository: chatRepository)
    lazy var sendChatMessageUseCase: SendChatMessageUseCase = DefaultSendChatMessageUseCase(repository: chatRepository)
    lazy var observeCurrentUserUseCase: ObserveCurrentUserUseCase = DefaultObserveCurrentUserUseCase(repository: userRepository)
    lazy var signInEmailUseCase: SignInEmailUseCase = DefaultSignInEmailUseCase(repository: userRepository)
    lazy var signOutUseCase: SignOutUseCase = DefaultSignOutUseCase(repository: userRepository)
}

