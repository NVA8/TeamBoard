import Foundation

public struct AnalyticsSnapshot: Codable, Equatable, Sendable {
    public var completedTasksPerMember: [Identifier<TeamMember>: Int]
    public var throughputPerWeek: [Date: Int]
    public var activeTasksPerStatus: [TaskStatus: Int]
    public var velocityTrend: [Date: Double]

    public init(
        completedTasksPerMember: [Identifier<TeamMember>: Int],
        throughputPerWeek: [Date: Int],
        activeTasksPerStatus: [TaskStatus: Int],
        velocityTrend: [Date: Double]
    ) {
        self.completedTasksPerMember = completedTasksPerMember
        self.throughputPerWeek = throughputPerWeek
        self.activeTasksPerStatus = activeTasksPerStatus
        self.velocityTrend = velocityTrend
    }
}

public protocol FetchAnalyticsUseCase: Sendable {
    func execute(teamId: Identifier<Team>) async throws -> AnalyticsSnapshot
}

