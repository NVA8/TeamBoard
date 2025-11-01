import SwiftUI

struct ChatScene: View {
    @StateObject private var viewModel: ChatViewModel

    init(viewModel: ChatViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                List(selection: $viewModel.selectedChannel) {
                    ForEach(viewModel.channels) { channel in
                        Button {
                            viewModel.selectedChannel = channel
                            viewModel.observeMessages()
                        } label: {
                            HStack {
                                Text(channel.title)
                                Spacer()
                                if channel.linkedBoardId != nil {
                                    Image(systemName: "link")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
                .frame(width: 260)

                VStack(spacing: 0) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 12) {
                                ForEach(viewModel.messages) { message in
                                    ChatBubble(message: message)
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

                    HStack {
                        TextField("Напишите сообщение…", text: $viewModel.inputText, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                        Button {
                            viewModel.sendMessage()
                        } label: {
                            Image(systemName: "paperplane.fill")
                                .foregroundStyle(.white)
                                .padding(10)
                                .background(Circle().fill(.blue))
                        }
                        .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding()
                }
            }
            .navigationTitle(viewModel.selectedChannel?.title ?? "Чаты")
        }
    }
}

private struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(message.body)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.blue.opacity(0.1)))
            Text(message.createdAt.formatted(date: .numeric, time: .shortened))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ChatScene(viewModel: ChatViewModel(environment: AppEnvironment()))
}

