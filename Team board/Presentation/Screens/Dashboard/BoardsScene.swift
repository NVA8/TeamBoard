import SwiftUI

struct BoardsScene: View {
    @StateObject private var viewModel: BoardsViewModel
    @Namespace private var namespace

    init(viewModel: BoardsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(.systemGray6),
                        Color(.systemBackground),
                        Color(.systemBlue).opacity(0.12)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 24) {
                    header

                    content
                        .animation(.easeInOut(duration: 0.2), value: viewModel.boards)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }
            .navigationTitle("Командные доски")
            .navigationBarTitleDisplayMode(.automatic)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.createBoard()
                    } label: {
                        Label("Новая доска", systemImage: "plus")
                            .fontWeight(.semibold)
                    }
                    .tint(.blue)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Рабочее пространство")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Ваши командные доски")
                .font(.largeTitle.bold())
                .foregroundStyle(.primary)
            Text("Отслеживайте прогресс, делитесь контекстом и синхронизируйтесь с командой в реальном времени.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.06), radius: 18, y: 14)
        )
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            VStack(spacing: 16) {
                ProgressView("Загрузка досок…")
                    .progressViewStyle(.automatic)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else if viewModel.boards.isEmpty {
            VStack(spacing: 20) {
                Image(systemName: "rectangle.stack.badge.plus")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(.blue)
                Text("Пока нет досок")
                    .font(.title3.bold())
                Text("Создайте первую доску, чтобы команда могла планировать и отслеживать задачи.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Button {
                    viewModel.createBoard()
                } label: {
                    Label("Создать доску", systemImage: "plus")
                        .frame(maxWidth: 220)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(32)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 280), spacing: 20)],
                    spacing: 20
                ) {
                    ForEach(viewModel.boards) { board in
                        NavigationLink {
                            BoardDetailScene(board: board, environment: viewModel.environment)
                        } label: {
                            BoardCard(board: board)
                                .matchedGeometryEffect(id: board.id, in: namespace)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                viewModel.deleteBoard(board)
                            } label: {
                                Label("Удалить", systemImage: "trash")
                            }
                        }
                        .draggable(board.name)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
}

private struct BoardCard: View {
    let board: Board

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(board.name)
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundStyle(.primary)
            Text(board.description)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(3)
            Spacer()
            HStack {
                Label("\(board.columns.count) колонок", systemImage: "square.grid.3x1.below.line.grid.1x2")
                Spacer()
                Label("Обновлено \(board.updatedAt.formatted(date: .numeric, time: .shortened))", systemImage: "clock")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 190, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(.systemBackground),
                            Color(.systemBackground).opacity(0.9),
                            Color(.systemBlue).opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.4), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 12)
    }
}

#Preview {
    BoardsScene(viewModel: BoardsViewModel(environment: AppEnvironment()))
}
