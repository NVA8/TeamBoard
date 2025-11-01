import SwiftUI

struct BoardDetailScene: View {
    @StateObject private var viewModel: BoardDetailViewModel
    @Namespace private var namespace

    init(board: Board, environment: AppEnvironment) {
        _viewModel = StateObject(wrappedValue: BoardDetailViewModel(board: board, environment: environment))
    }

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 24) {
                ForEach(viewModel.board.columns) { column in
                    BoardColumnView(
                        column: column,
                        tasks: viewModel.tasksByColumn[column.id] ?? []
                    )
                    .frame(width: 320)
                    .overlay {
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(.primary.opacity(0.05), lineWidth: 1)
                    }
                    .background {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(.thickMaterial)
                            .matchedGeometryEffect(id: column.id, in: namespace)
                    }
                    .contextMenu {
                        Button("Добавить задачу") { }
                        Button("Переименовать") { }
                    }
                    .dropDestination(for: Task.self) { items, location in
                        guard let task = items.first else { return false }
                        viewModel.moveTask(task, from: column.id, to: column.id, destinationIndex: 0)
                        return true
                    }
                }
            }
            .padding()
        }
        .navigationTitle(viewModel.board.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    // Present quick add sheet
                } label: {
                    Label("Новая задача", systemImage: "square.and.pencil")
                }
            }
        }
    }
}

private struct BoardColumnView: View {
    let column: TaskColumn
    let tasks: [Task]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(column.title)
                .font(.headline)
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(tasks) { task in
                        TaskCard(task: task)
                            .draggable(task) {
                                TaskCard(task: task)
                                    .opacity(0.7)
                            }
                    }
                }
                .padding(.bottom, 16)
            }
        }
        .padding()
    }
}

private struct TaskCard: View {
    let task: Task

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(task.title)
                    .font(.headline)
                Spacer()
                Circle()
                    .fill(color(for: task.priority))
                    .frame(width: 10, height: 10)
            }
            Text(task.detail)
                .font(.subheadline)
                .lineLimit(3)
            HStack {
                if let dueDate = task.dueDate {
                    Label(dueDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                }
                Spacer()
                Label(task.status.rawValue.capitalized, systemImage: "flag")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(.regularMaterial))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
    }

    private func color(for priority: TaskPriority) -> Color {
        switch priority {
        case .low: .green
        case .medium: .yellow
        case .high: .orange
        case .critical: .red
        }
    }
}

#Preview {
    let env = AppEnvironment()
    let board = Board(
        name: "Design Sprint",
        description: "UI/UX experiments",
        ownerId: Identifier<TeamMember>("owner"),
        columns: [
            TaskColumn(title: "To Do", order: 0),
            TaskColumn(title: "In Progress", order: 1),
            TaskColumn(title: "Done", order: 2)
        ],
        members: []
    )
    BoardDetailScene(board: board, environment: env)
}
