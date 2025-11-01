import Foundation
#if canImport(FirebaseStorage)
import FirebaseStorage
#endif

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var channels: [ChatChannel] = []
    @Published var selectedChannel: ChatChannel?
    @Published var messages: [ChatMessage] = []
    @Published var inputText = ""

    @Published var isSelectionMode = false
    @Published var selectedMessages: Set<Identifier<ChatMessage>> = []
    @Published var isTaskSheetPresented = false
    @Published var taskDraftTitle = ""
    @Published var taskDraftDescription = ""
    @Published var taskDraftBoard: Board?
    @Published var taskDraftColumn: TaskColumn?
    @Published var taskDraftAssignee: Identifier<TeamMember>?
    @Published var availableBoards: [Board] = []
    @Published var teamMembers: [TeamMember] = []
    @Published var currentUser: TeamMember?
    @Published var alertMessage: String?
    @Published var isSavingTask = false
    @Published var isSendingVoiceMessage = false

    let voiceService = VoiceMessageService()

    private let environment: AppEnvironment
    private let teamId = Identifier<Team>("demo-team")
    private var messageStreamTask: _Concurrency.Task<Void, Never>?
    private var boardsStreamTask: _Concurrency.Task<Void, Never>?
    private var membersStreamTask: _Concurrency.Task<Void, Never>?

    init(environment: AppEnvironment) {
        self.environment = environment
        loadStubChannels()
        observeBoards()
        observeTeamMembers()
        loadCurrentUser()
    }

    deinit {
        messageStreamTask?.cancel()
        boardsStreamTask?.cancel()
        membersStreamTask?.cancel()
    }

    func loadStubChannels() {
        channels = [
            ChatChannel(id: Identifier("general"), title: "Общий чат", participantIds: []),
            ChatChannel(title: "Design Team", participantIds: []),
            ChatChannel(title: "Dev Updates", participantIds: [])
        ]
        selectedChannel = channels.first
        observeMessages()
    }

    func observeMessages() {
        messageStreamTask?.cancel()
        guard let channel = selectedChannel else { return }
        messageStreamTask = _Concurrency.Task {
            do {
                for try await messages in environment.observeChatMessagesUseCase.execute(channelId: channel.id) {
                    await MainActor.run {
                        self.messages = messages
                        self.syncSelectionWithLatestMessages()
                    }
                }
            } catch {
                await MainActor.run {
                    self.alertMessage = error.localizedDescription
                }
            }
        }
    }

    func sendMessage() {
        guard let channel = selectedChannel else { return }
        let body = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return }
        let authorId = currentUser?.id ?? Identifier<TeamMember>("guest")
        let message = ChatMessage(
            channelId: channel.id,
            authorId: authorId,
            body: body
        )
        _Concurrency.Task {
            do {
                try await environment.sendChatMessageUseCase.execute(message)
                await MainActor.run {
                    inputText = ""
                }
            } catch {
                await MainActor.run {
                    alertMessage = error.localizedDescription
                }
            }
        }
    }

    func startSelection(with message: ChatMessage) {
        if !isSelectionMode {
            isSelectionMode = true
            selectedMessages = [message.id]
        } else {
            toggleSelection(for: message)
        }
    }

    func toggleSelection(for message: ChatMessage) {
        if selectedMessages.contains(message.id) {
            selectedMessages.remove(message.id)
        } else {
            selectedMessages.insert(message.id)
        }
        if selectedMessages.isEmpty {
            isSelectionMode = false
        }
    }

    func isMessageSelected(_ message: ChatMessage) -> Bool {
        selectedMessages.contains(message.id)
    }

    func cancelSelection() {
        selectedMessages.removeAll()
        isSelectionMode = false
    }

    func prepareTaskDraft() {
        let orderedMessages = selectedMessagesOrdered()
        let fallbackTitle = orderedMessages.first?.body.isEmpty == false
            ? orderedMessages.first!.body
            : "Новая задача"
        taskDraftTitle = fallbackTitle
        taskDraftDescription = orderedMessages
            .map { message in
                var components: [String] = []
                if !message.body.isEmpty {
                    components.append(message.body)
                }
                if let transcript = message.voiceTranscription, !transcript.isEmpty, transcript != message.body {
                    components.append("Транскрипт: \(transcript)")
                }
                return components.joined(separator: "\n")
            }
            .joined(separator: "\n\n")
        taskDraftAssignee = nil
        if let board = availableBoards.first {
            taskDraftBoard = board
            taskDraftColumn = board.columns.sorted(by: { $0.order < $1.order }).first
        } else {
            taskDraftBoard = nil
            taskDraftColumn = nil
        }
        isTaskSheetPresented = true
    }

    func selectBoard(_ board: Board) {
        taskDraftBoard = board
        taskDraftColumn = board.columns.sorted(by: { $0.order < $1.order }).first
    }

    func createTaskFromSelection() {
        guard let board = taskDraftBoard, let column = taskDraftColumn else {
            alertMessage = "Выберите доску и колонку, чтобы создать задачу."
            return
        }
        let title = taskDraftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let detail = taskDraftDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            alertMessage = "Введите название задачи."
            return
        }
        guard let creatorId = currentUser?.id ?? selectedMessagesOrdered().first?.authorId else {
            alertMessage = "Не удалось определить автора задачи."
            return
        }
        let task = Task(
            title: title,
            detail: detail,
            assigneeId: taskDraftAssignee,
            creatorId: creatorId,
            status: status(for: column),
            priority: .medium
        )
        isSavingTask = true
        _Concurrency.Task {
            do {
                try await environment.createTaskUseCase.execute(task, boardId: board.id, columnId: column.id)
                await MainActor.run {
                    isSavingTask = false
                    isTaskSheetPresented = false
                    cancelSelection()
                }
            } catch {
                await MainActor.run {
                    isSavingTask = false
                    alertMessage = error.localizedDescription
                }
            }
        }
    }

    func startVoiceRecording() {
        _Concurrency.Task {
            do {
                try await voiceService.startRecording()
            } catch {
                await MainActor.run {
                    alertMessage = error.localizedDescription
                }
            }
        }
    }

    func stopVoiceRecordingAndSend() {
        guard selectedChannel != nil else {
            alertMessage = "Выберите канал для отправки сообщения."
            return
        }
        isSendingVoiceMessage = true
        _Concurrency.Task {
            do {
                let result = try await voiceService.stopRecording()
                try await sendVoiceMessage(with: result)
            } catch {
                await MainActor.run {
                    alertMessage = error.localizedDescription
                    isSendingVoiceMessage = false
                }
                voiceService.cancelRecording()
            }
        }
    }

    func cancelVoiceRecording() {
        voiceService.cancelRecording()
    }

    private func sendVoiceMessage(with result: VoiceMessageService.Result) async throws {
        guard let channel = selectedChannel else { return }
        let uploadedURL = try await uploadVoiceNoteIfNeeded(at: result.fileURL)
        let authorId = currentUser?.id ?? Identifier<TeamMember>("guest")
        let transcript = result.transcript?.trimmingCharacters(in: .whitespacesAndNewlines)
        let body: String
        if let transcript, !transcript.isEmpty {
            body = transcript
        } else {
            body = "Голосовое сообщение"
        }

        let message = ChatMessage(
            channelId: channel.id,
            authorId: authorId,
            body: body,
            voiceNoteURL: uploadedURL,
            voiceDuration: result.duration,
            voiceTranscription: transcript
        )
        do {
            try await environment.sendChatMessageUseCase.execute(message)
            try? FileManager.default.removeItem(at: result.fileURL)
            await MainActor.run {
                isSendingVoiceMessage = false
            }
        } catch {
            await MainActor.run {
                alertMessage = error.localizedDescription
                isSendingVoiceMessage = false
            }
            throw error
        }
    }

    private func observeBoards() {
        boardsStreamTask?.cancel()
        boardsStreamTask = _Concurrency.Task {
            do {
                for try await boards in environment.observeBoardsUseCase.execute(teamId: teamId) {
                    await MainActor.run {
                        self.availableBoards = boards
                        if self.taskDraftBoard == nil, let first = boards.first {
                            self.taskDraftBoard = first
                            self.taskDraftColumn = first.columns.sorted(by: { $0.order < $1.order }).first
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.alertMessage = error.localizedDescription
                }
            }
        }
    }

    private func observeTeamMembers() {
        membersStreamTask?.cancel()
        membersStreamTask = _Concurrency.Task {
            do {
                for try await members in environment.observeTeamMembersUseCase.execute(teamId: teamId) {
                    await MainActor.run {
                        self.teamMembers = members
                    }
                }
            } catch {
                await MainActor.run {
                    self.alertMessage = error.localizedDescription
                }
            }
        }
    }

    private func loadCurrentUser() {
        _Concurrency.Task {
            do {
                let user = try await environment.observeCurrentUserUseCase.execute()
                await MainActor.run {
                    self.currentUser = user
                }
            } catch {
                await MainActor.run {
                    self.alertMessage = error.localizedDescription
                }
            }
        }
    }

    private func syncSelectionWithLatestMessages() {
        let existingIds = Set(messages.map(\.id))
        selectedMessages = selectedMessages.filter { existingIds.contains($0) }
        if selectedMessages.isEmpty {
            isSelectionMode = false
        }
    }

    private func selectedMessagesOrdered() -> [ChatMessage] {
        messages.filter { selectedMessages.contains($0.id) }
    }

    private func status(for column: TaskColumn) -> TaskStatus {
        let title = column.title.lowercased()
        if title.contains("backlog") {
            return .backlog
        } else if title.contains("review") || title.contains("ревью") {
            return .review
        } else if title.contains("done") || title.contains("готов") {
            return .done
        } else if title.contains("progress") || title.contains("работ") {
            return .inProgress
        } else if title.contains("todo") || title.contains("дел") {
            return .todo
        } else {
            return .todo
        }
    }

    private func uploadVoiceNoteIfNeeded(at url: URL) async throws -> URL {
#if canImport(FirebaseStorage)
        let storage = Storage.storage()
        let reference = storage.reference().child("voiceNotes/\(UUID().uuidString).m4a")
        let metadata = StorageMetadata()
        metadata.contentType = "audio/m4a"
        return try await withCheckedThrowingContinuation { continuation in
            reference.putFile(from: url, metadata: metadata) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                reference.downloadURL { downloadURL, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }
                    guard let downloadURL else {
                        continuation.resume(throwing: VoiceMessageError.featureUnavailable)
                        return
                    }
                    continuation.resume(returning: downloadURL)
                }
            }
        }
#else
        return url
#endif
    }
}
