import Foundation

@MainActor
final class AnalyticsViewModel: ObservableObject {
    @Published var snapshot: AnalyticsSnapshot?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let environment: AppEnvironment
    private let teamId = Identifier<Team>("demo-team")

    init(environment: AppEnvironment) {
        self.environment = environment
        loadAnalytics()
    }

    func loadAnalytics() {
        _Concurrency.Task {
            isLoading = true
            defer { isLoading = false }
            do {
                // When analytics repository is ready, inject via environment.
                let sample = AnalyticsSnapshot(
                    completedTasksPerMember: [.init("alice"): 14, .init("bob"): 9, .init("carol"): 23],
                    throughputPerWeek: [
                        Date().addingTimeInterval(-21 * 24 * 3600): 12,
                        Date().addingTimeInterval(-14 * 24 * 3600): 18,
                        Date().addingTimeInterval(-7 * 24 * 3600): 22,
                        Date(): 25
                    ],
                    activeTasksPerStatus: [.todo: 11, .inProgress: 6, .review: 3, .done: 42],
                    velocityTrend: [
                        Date().addingTimeInterval(-21 * 24 * 3600): 0.8,
                        Date().addingTimeInterval(-14 * 24 * 3600): 1.1,
                        Date().addingTimeInterval(-7 * 24 * 3600): 1.4,
                        Date(): 1.6
                    ]
                )
                snapshot = sample
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
