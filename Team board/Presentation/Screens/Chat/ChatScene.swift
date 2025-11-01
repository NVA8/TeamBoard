import SwiftUI

struct ChatScene: View {
    @StateObject private var viewModel: ChatViewModel
    @ObservedObject private var voiceService: VoiceMessageService
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    init(viewModel: ChatViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _voiceService = ObservedObject(wrappedValue: viewModel.voiceService)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemGray6),
                        Color(.systemBlue).opacity(0.12)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                Group {
                    if isCompactLayout {
                        compactLayout
                    } else {
                        regularLayout
                    }
                }
                .transition(.opacity.combined(with: .scale))
            }
            .navigationTitle(viewModel.selectedChannel?.title ?? "Чаты")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if viewModel.isSelectionMode {
                        Button("Отмена") {
                            viewModel.cancelSelection()
                        }
                    } else {
                        Button("Выбрать") {
                            viewModel.isSelectionMode = true
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.isTaskSheetPresented) {
            TaskCreationSheet(viewModel: viewModel)
                .presentationDetents([.medium, .large])
        }
        .alert("Ошибка", isPresented: Binding<Bool>(
            get: { viewModel.alertMessage != nil },
            set: { newValue in
                if !newValue {
                    viewModel.alertMessage = nil
                }
            }
        )) {
            Button("Ок", role: .cancel) {
                viewModel.alertMessage = nil
            }
        } message: {
            Text(viewModel.alertMessage ?? "")
        }
    }
}

private extension ChatScene {
    var channelChips: some View {
        HStack(spacing: 12) {
            ForEach(viewModel.channels) { channel in
                channelChip(for: channel)
            }
        }
    }

    func channelChip(for channel: ChatChannel) -> some View {
        let isSelected = viewModel.selectedChannel == channel
        return Button {
            viewModel.selectedChannel = channel
            viewModel.observeMessages()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isSelected ? "bubble.left.and.bubble.right.fill" : "bubble.left.and.bubble.right")
                    .font(.subheadline.weight(.semibold))
                Text(channel.title)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(Color.blue.gradient) : AnyShapeStyle(Color(.systemGray5)))
            )
        }
    }

    var isCompactLayout: Bool { horizontalSizeClass == .compact }

    var regularLayout: some View {
        HStack(spacing: 20) {
            channelList
                .frame(width: 260)

            messagesPanel
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
    }

    var compactLayout: some View {
        VStack(spacing: 16) {
            ScrollView(.horizontal, showsIndicators: false) {
                channelChips
                    .padding(.horizontal, 8)
            }

            messagesPanel
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
    }

    var channelList: some View {
        List(selection: $viewModel.selectedChannel) {
            Section("Каналы") {
                ForEach(viewModel.channels) { channel in
                    Button {
                        viewModel.selectedChannel = channel
                        viewModel.observeMessages()
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(channel.title)
                                    .font(.headline)
                                if channel.linkedBoardId != nil {
                                    Label("Связана с доской", systemImage: "link")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.06), radius: 18, y: 12)
        )
    }

    var messagesPanel: some View {
        VStack(spacing: 0) {
            if viewModel.isSelectionMode {
                SelectionToolbar(
                    selectedCount: viewModel.selectedMessages.count,
                    onCreateTask: { viewModel.prepareTaskDraft() },
                    onCancel: { viewModel.cancelSelection() }
                )
            }

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            ChatMessageRow(
                                message: message,
                                isSelectionMode: viewModel.isSelectionMode,
                                isSelected: viewModel.isMessageSelected(message),
                                onToggleSelection: { viewModel.toggleSelection(for: message) },
                                onStartSelection: { viewModel.startSelection(with: message) }
                            )
                            .id(message.id)
                        }
                    }
                    .padding(16)
                }
                .onChange(of: viewModel.messages.count) { _ in
                    if let last = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            VStack(spacing: 12) {
                switch voiceService.state {
                case .recording:
                    RecordingIndicator(
                        duration: voiceService.currentDuration,
                        onStop: { viewModel.stopVoiceRecordingAndSend() },
                        onCancel: { viewModel.cancelVoiceRecording() }
                    )
                case .processing:
                    ProcessingIndicator(text: "Обработка голосового сообщения…")
                case .failed(let message):
                    ErrorIndicator(text: message) {
                        viewModel.cancelVoiceRecording()
                    }
                case .idle:
                    EmptyView()
                }

                if viewModel.isSendingVoiceMessage {
                    ProcessingIndicator(text: "Отправка голосового сообщения…")
                }

                HStack(alignment: .bottom, spacing: 12) {
                    TextField("Напишите сообщение…", text: $viewModel.inputText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .disabled(viewModel.isSendingVoiceMessage || voiceService.state == .processing)

                    Button {
                        viewModel.sendMessage()
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(Circle().fill(.blue))
                    }
                    .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSendingVoiceMessage)

                    VoiceRecorderButton(
                        state: voiceService.state,
                        isBusy: viewModel.isSendingVoiceMessage,
                        onStart: { viewModel.startVoiceRecording() },
                        onStop: { viewModel.stopVoiceRecordingAndSend() }
                    )
                }
            }
            .padding()
        }
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.thinMaterial)
                .shadow(color: .black.opacity(0.04), radius: 16, y: 10)
        )
    }
}

private struct ChatMessageRow: View {
    let message: ChatMessage
    let isSelectionMode: Bool
    let isSelected: Bool
    let onToggleSelection: () -> Void
    let onStartSelection: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if isSelectionMode {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .imageScale(.large)
            }
            ChatBubble(message: message)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(isSelected ? Color.blue.opacity(0.08) : Color.clear)
                )
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            if isSelectionMode {
                onToggleSelection()
            }
        }
        .onLongPressGesture {
            onStartSelection()
        }
    }
}

private struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let voiceURL = message.voiceNoteURL, let duration = message.voiceDuration {
                VoiceMessagePlayerView(url: voiceURL, duration: duration)
            }

            if !message.body.isEmpty {
                Text(message.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let transcript = message.voiceTranscription,
               transcript != message.body,
               !transcript.isEmpty {
                Text("Транскрипт: \(transcript)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(message.createdAt.formatted(date: .numeric, time: .shortened))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(.systemBlue).opacity(0.12),
                            Color(.systemBackground)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.45), lineWidth: 1)
                )
        )
    }
}

private struct SelectionToolbar: View {
    let selectedCount: Int
    let onCreateTask: () -> Void
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Выбрано: \(selectedCount)")
                    .font(.subheadline.weight(.semibold))
                Text("Соберите контекст и превратите диалог в задачу.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                onCreateTask()
            } label: {
                Label("Создать задачу", systemImage: "square.and.pencil")
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedCount == 0)
            Button("Отмена", role: .cancel) {
                onCancel()
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }
}

private struct RecordingIndicator: View {
    let duration: TimeInterval
    let onStop: () -> Void
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Label("Запись \(formatted(duration))", systemImage: "waveform")
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.red.opacity(0.1)))
            Spacer()
            Button {
                onStop()
            } label: {
                Image(systemName: "stop.fill")
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Circle().fill(.red))
            }
            Button {
                onCancel()
            } label: {
                Image(systemName: "xmark")
                    .padding(10)
                    .background(Circle().strokeBorder(.red))
            }
        }
        .font(.subheadline)
    }

    private func formatted(_ duration: TimeInterval) -> String {
        let seconds = Int(duration.rounded())
        let minutes = seconds / 60
        let rest = seconds % 60
        return String(format: "%02d:%02d", minutes, rest)
    }
}

private struct ProcessingIndicator: View {
    let text: String

    var body: some View {
        HStack {
            ProgressView()
            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}

private struct ErrorIndicator: View {
    let text: String
    let onDismiss: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text(text)
                .font(.footnote)
            Spacer()
            Button("Закрыть") {
                onDismiss()
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.yellow.opacity(0.1)))
    }
}

private struct VoiceRecorderButton: View {
    let state: VoiceMessageService.RecordingState
    let isBusy: Bool
    let onStart: () -> Void
    let onStop: () -> Void

    var body: some View {
        Button {
            switch state {
            case .idle, .failed:
                onStart()
            case .recording:
                onStop()
            case .processing:
                break
            }
        } label: {
            Image(systemName: iconName)
                .foregroundStyle(.white)
                .padding(10)
                .background(Circle().fill(color))
        }
        .buttonStyle(.plain)
        .disabled(isBusy || state == .processing)
    }

    private var iconName: String {
        switch state {
        case .idle, .failed:
            return "mic.fill"
        case .recording:
            return "stop.fill"
        case .processing:
            return "hourglass"
        }
    }

    private var color: Color {
        switch state {
        case .idle, .failed:
            return Color.purple
        case .recording:
            return Color.red
        case .processing:
            return Color.gray
        }
    }
}

private struct TaskCreationSheet: View {
    @ObservedObject var viewModel: ChatViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section("Детали задачи") {
                    TextField("Название", text: $viewModel.taskDraftTitle)
                    TextEditor(text: $viewModel.taskDraftDescription)
                        .frame(height: 120)
                }

                Section("Доска") {
                    Picker("Выберите доску", selection: Binding<Identifier<Board>?>(
                        get: { viewModel.taskDraftBoard?.id },
                        set: { id in
                            if let id, let board = viewModel.availableBoards.first(where: { $0.id == id }) {
                                viewModel.selectBoard(board)
                            }
                        }
                    )) {
                        ForEach(viewModel.availableBoards) { board in
                            Text(board.name)
                                .tag(Optional(board.id))
                        }
                    }

                    if let board = viewModel.taskDraftBoard {
                        Picker("Колонка", selection: Binding<Identifier<TaskColumn>?>(
                            get: { viewModel.taskDraftColumn?.id },
                            set: { id in
                                if let id, let column = board.columns.first(where: { $0.id == id }) {
                                    viewModel.taskDraftColumn = column
                                }
                            }
                        )) {
                            ForEach(board.columns) { column in
                                Text(column.title)
                                    .tag(Optional(column.id))
                            }
                        }
                    }
                }

                Section("Исполнитель") {
                    Picker("Назначить", selection: Binding<Identifier<TeamMember>?>(
                        get: { viewModel.taskDraftAssignee },
                        set: { viewModel.taskDraftAssignee = $0 }
                    )) {
                        Text("Не назначено")
                            .tag(Optional<Identifier<TeamMember>>.none)
                        ForEach(viewModel.teamMembers) { member in
                            Text(member.displayName)
                                .tag(Optional(member.id))
                        }
                    }
                }
            }
            .navigationTitle("Задача из чата")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        viewModel.isTaskSheetPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isSavingTask {
                        ProgressView()
                    } else {
                        Button("Создать") {
                            viewModel.createTaskFromSelection()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ChatScene(viewModel: ChatViewModel(environment: AppEnvironment()))
}
