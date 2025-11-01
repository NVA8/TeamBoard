import Foundation

@MainActor
final class AppEnvironment: ObservableObject {
    let taskCache = TaskCacheService()

#if canImport(FirebaseFirestore)
    lazy var boardRepository: BoardRepository = FirestoreBoardRepository(cache: taskCache)
    lazy var taskRepository: TaskRepository = FirestoreTaskRepository(cache: taskCache)
    lazy var chatRepository: ChatRepository = FirestoreChatRepository()
#else
    lazy var boardRepository: BoardRepository = InMemoryBoardRepository()
    lazy var taskRepository: TaskRepository = InMemoryTaskRepository()
    lazy var chatRepository: ChatRepository = InMemoryChatRepository()
#endif
#if canImport(FirebaseAuth)
    lazy var userRepository: UserRepository = FirebaseAuthRepository()
#else
    lazy var userRepository: UserRepository = InMemoryGuestAuthRepository()
#endif
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
    lazy var signInGuestUseCase: SignInGuestUseCase = DefaultSignInGuestUseCase(repository: userRepository)
    lazy var signOutUseCase: SignOutUseCase = DefaultSignOutUseCase(repository: userRepository)
    lazy var observeTeamMembersUseCase: ObserveTeamMembersUseCase = DefaultObserveTeamMembersUseCase(repository: userRepository)
}
