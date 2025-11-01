import SwiftUI
import Charts

struct AnalyticsScene: View {
    @StateObject private var viewModel: AnalyticsViewModel

    init(viewModel: AnalyticsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Генерируем аналитики…")
                } else if let snapshot = viewModel.snapshot {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            Text("Продуктивность команды")
                                .font(.title2.bold())

                            Chart {
                                ForEach(Array(snapshot.completedTasksPerMember.keys), id: \.self) { memberId in
                                    BarMark(
                                        x: .value("Участник", memberId.rawValue),
                                        y: .value("Задач закрыто", snapshot.completedTasksPerMember[memberId] ?? 0)
                                    )
                                }
                            }
                            .chartYAxisLabel("Закрыто задач")
                            .frame(height: 220)

                            Text("Throughput по неделям")
                                .font(.title3.bold())

                            Chart {
                                ForEach(snapshot.throughputPerWeek.keys.sorted(), id: \.self) { week in
                                    LineMark(
                                        x: .value("Неделя", week),
                                        y: .value("Throughput", snapshot.throughputPerWeek[week] ?? 0)
                                    )
                                    PointMark(
                                        x: .value("Неделя", week),
                                        y: .value("Throughput", snapshot.throughputPerWeek[week] ?? 0)
                                    )
                                }
                            }
                            .frame(height: 220)

                            Text("Статус задач")
                                .font(.title3.bold())

                            Chart {
                                ForEach(TaskStatus.allCases, id: \.self) { status in
                                    SectorMark(
                                        angle: .value("Tasks", snapshot.activeTasksPerStatus[status] ?? 0),
                                        innerRadius: .ratio(0.55),
                                        angularInset: 1.5
                                    )
                                    .foregroundStyle(color(for: status))
                                    .annotation(position: .overlay) {
                                        Text(status.rawValue.capitalized)
                                            .font(.caption2)
                                    }
                                }
                            }
                            .frame(height: 240)
                        }
                        .padding()
                    }
                } else {
                    Text("Нет данных для отображения")
                }
            }
            .navigationTitle("Аналитика")
        }
    }

    private func color(for status: TaskStatus) -> Color {
        switch status {
        case .backlog: .gray
        case .todo: .blue
        case .inProgress: .orange
        case .review: .purple
        case .done: .green
        }
    }
}

private extension TaskStatus {
    static var allCases: [TaskStatus] {
        [.backlog, .todo, .inProgress, .review, .done]
    }
}

#Preview {
    AnalyticsScene(viewModel: AnalyticsViewModel(environment: AppEnvironment()))
}

