import SwiftUI
import Charts

struct AnalyticsScene: View {
    @StateObject private var viewModel: AnalyticsViewModel

    init(viewModel: AnalyticsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemGray6),
                        Color(.systemIndigo).opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                content
            }
            .navigationTitle("Аналитика")
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView("Генерируем аналитики…")
                .progressViewStyle(.circular)
        } else if let snapshot = viewModel.snapshot {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    hero

                    AnalyticsCard(title: "Продуктивность команды", caption: "Закрытые задачи по участникам") {
                        Chart {
                            ForEach(Array(snapshot.completedTasksPerMember.keys), id: \.self) { memberId in
                                BarMark(
                                    x: .value("Участник", memberId.rawValue),
                                    y: .value("Задач закрыто", snapshot.completedTasksPerMember[memberId] ?? 0)
                                )
                                .annotation(position: .top) {
                                    Text("\(snapshot.completedTasksPerMember[memberId] ?? 0)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .chartYAxisLabel("Закрыто задач")
                        .chartLegend(.hidden)
                        .frame(height: 240)
                    }

                    AnalyticsCard(title: "Throughput по неделям", caption: "Темп выполнения задач в динамике") {
                        Chart {
                            ForEach(snapshot.throughputPerWeek.keys.sorted(), id: \.self) { week in
                                LineMark(
                                    x: .value("Неделя", week),
                                    y: .value("Throughput", snapshot.throughputPerWeek[week] ?? 0)
                                )
                                .interpolationMethod(.catmullRom)
                                PointMark(
                                    x: .value("Неделя", week),
                                    y: .value("Throughput", snapshot.throughputPerWeek[week] ?? 0)
                                )
                                .symbolSize(64)
                            }
                        }
                        .frame(height: 240)
                    }

                    AnalyticsCard(title: "Статус задач", caption: "Распределение активных задач по стадиям") {
                        Chart {
                            ForEach(TaskStatus.allCases, id: \.self) { status in
                                SectorMark(
                                    angle: .value("Tasks", snapshot.activeTasksPerStatus[status] ?? 0),
                                    innerRadius: .ratio(0.55),
                                    angularInset: 1.5
                                )
                                .foregroundStyle(color(for: status))
                                .annotation(position: .overlay) {
                                    VStack(spacing: 2) {
                                        Text(status.rawValue.capitalized)
                                            .font(.caption2)
                                        Text("\(snapshot.activeTasksPerStatus[status] ?? 0)")
                                            .font(.caption2.bold())
                                    }
                                    .foregroundStyle(.white)
                                }
                            }
                        }
                        .frame(height: 260)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
        } else {
            VStack(spacing: 14) {
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("Нет данных для отображения")
                    .font(.headline)
                Text("Создайте доски и задачи, чтобы видеть метрики команды в реальном времени.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Отчётность за неделю")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Картина эффективности команды")
                .font(.largeTitle.bold())
            Text("Следите за темпом выполнения задач, дисперсией статусов и вкладом каждого участника.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.08), radius: 20, y: 14)
        )
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

private struct AnalyticsCard<Content: View>: View {
    let title: String
    let caption: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.title3.bold())
                Text(caption)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            content
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 16, y: 12)
    }
}

#Preview {
    AnalyticsScene(viewModel: AnalyticsViewModel(environment: AppEnvironment()))
}
