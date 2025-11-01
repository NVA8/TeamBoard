import SwiftUI

struct BoardsScene: View {
    @StateObject private var viewModel: BoardsViewModel
    @Namespace private var namespace

    init(viewModel: BoardsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Загрузка досок…")
                } else if viewModel.boards.isEmpty {
                    VStack(spacing: 16) {
                        Text("Пока нет досок")
                            .font(.headline)
                        Button("Создать первую доску") {
                            viewModel.createBoard()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    ScrollView(.vertical) {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 16)], spacing: 16) {
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
                        .padding()
                    }
                }
            }
            .navigationTitle("Командные доски")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.createBoard()
                    } label: {
                        Label("Новая доска", systemImage: "plus")
                    }
                }
            }
        }
    }
}

private struct BoardCard: View {
    let board: Board

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(board.name)
                .font(.headline)
            Text(board.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            HStack {
                Label("\(board.columns.count) колонок", systemImage: "square.grid.3x1.below.line.grid.1x2")
                Spacer()
                Label("Обновлено \(board.updatedAt.formatted(date: .numeric, time: .shortened))", systemImage: "clock")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.ultraThickMaterial))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

#Preview {
    BoardsScene(viewModel: BoardsViewModel(environment: AppEnvironment()))
}
